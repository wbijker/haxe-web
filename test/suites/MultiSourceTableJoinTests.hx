package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;
using codequery.testing.SourceAccess;

@tableName("trips")
class MultiTrip {
	public var id:Int = 0;
	public var tripNumber:String = "";

	public function new() {}

	/** The inbound leg of this trip, matched on the trip number they share. */
	public static function WithInbound():(MultiTrip, MultiInbound) -> Bool {
		return (t, i) -> i.tripNumber == t.tripNumber;
	}
}

@tableName("incidents")
class MultiIncident {
	public var id:Int = 0;
	public var identification:String = "";

	public function new() {}
}

@tableName("inbounds")
class MultiInbound {
	public var id:Int = 0;
	public var tripNumber:String = "";

	public function new() {}

	/** Who drove it. */
	public static function WithDriver():(MultiInbound, MultiDriver) -> Bool {
		return (i, d) -> d.tripNumber == i.tripNumber;
	}
}

@tableName("drivers")
class MultiDriver {
	public var id:Int = 0;
	public var tripNumber:String = "";

	public function new() {}
}

/**
	`MultiSourceTableJoinTests.cs` — joining a `DbTable` directly once the query already has two or
	three sources, and a relationship on a query that wide.
**/
class MultiSourceTableJoinTests extends TestCase {
	static function incidents():DbTable<MultiIncident> {
		return Query.table(MultiIncident);
	}

	static function trips():DbTable<MultiTrip> {
		return Query.table(MultiTrip);
	}

	static function inbounds():DbTable<MultiInbound> {
		return Query.table(MultiInbound);
	}

	static function drivers():DbTable<MultiDriver> {
		return Query.table(MultiDriver);
	}

	/**
		The join at `index` brings in `table` and matches its `joinedColumn` against `otherColumn` of
		the source at `otherIndex` — 0 being the statement's own source and 1 upwards its earlier joins.
	**/
	static function assertJoinsOn(select:SelectExpression, index:Int, type:JoinType, table:String,
			joinedColumn:String, otherIndex:Int, otherColumn:String):Void {
		final join = select.join(index);
		Assert.equals(type, join.Type);
		Assert.equals(table, join.Source.tableName());

		final other = otherIndex == 0 ? select.Source : select.join(otherIndex - 1).Source;
		final on = join.On.binary(Equal);

		// Either side may carry the joined table; what matters is that the two columns are the pair named.
		final joined = select.sourceOf(on.Left) == join.Source ? on.Left : on.Right;
		final against = joined == on.Left ? on.Right : on.Left;

		joined.column(joinedColumn);
		Assert.equals(join.Source.Alias, select.sourceAlias(joined));
		against.column(otherColumn);
		Assert.equals(other.Alias, select.sourceAlias(against));
	}

	/** The two statements join the same tables, the same way, on the same columns. */
	static function assertSameJoins(expected:SelectExpression, actual:SelectExpression):Void {
		Assert.equals(expected.selectTableName(), actual.selectTableName());
		Assert.equals(expected.Joins.length, actual.Joins.length);

		for (i in 0...expected.Joins.length) {
			Assert.equals(expected.join(i).Type, actual.join(i).Type);
			Assert.equals(expected.joinedTableName(i), actual.joinedTableName(i));

			final expectedOn = expected.joinOnBinary(i);
			final actualOn = actual.joinOnBinary(i);

			Assert.equals(expectedOn.Operator, actualOn.Operator);

			// Matched by source rather than by side: an equality means the same join written either way.
			assertSameColumn(expectedOn.Left, sideFrom(actualOn, expectedOn.Left.sourceIndex()));
			assertSameColumn(expectedOn.Right, sideFrom(actualOn, expectedOn.Right.sourceIndex()));
		}
	}

	static function sideFrom(on:BinarySqlExpression, sourceIndex:Int):ISqlExpression {
		return on.Left.sourceIndex() == sourceIndex ? on.Left : on.Right;
	}

	static function assertSameColumn(expected:ISqlExpression, actual:ISqlExpression):Void {
		final column = expected.column();
		actual.column(column.ColumnName);
		Assert.equals(expected.sourceIndex(), actual.sourceIndex());
	}

	function testLeftJoin_Table_OnTwoSourceQuery() {
		final select = incidents().From()
			.LeftJoin(trips(), (i, t) -> t.tripNumber == i.identification)
			.LeftJoin(inbounds(), (i, t, ti) -> ti.tripNumber == t.tripNumber)
			.ToExpression();

		Assert.equals("incidents", select.selectTableName());
		assertJoinsOn(select, 0, Left, "trips", "tripNumber", 0, "identification");
		assertJoinsOn(select, 1, Left, "inbounds", "tripNumber", 1, "tripNumber");
	}

	function testLeftJoin_Table_MatchesFromForm() {
		final tableForm = incidents().From()
			.LeftJoin(trips(), (i, t) -> t.tripNumber == i.identification)
			.LeftJoin(inbounds(), (i, t, ti) -> ti.tripNumber == t.tripNumber)
			.ToExpression();

		final fromForm = incidents().From()
			.LeftJoin(trips().From(), (i, t) -> t.tripNumber == i.identification)
			.LeftJoin(inbounds().From(), (i, t, ti) -> ti.tripNumber == t.tripNumber)
			.ToExpression();

		assertSameJoins(fromForm, tableForm);
	}

	function testInnerJoin_Table_OnThreeSourceQuery() {
		final select = incidents().From()
			.InnerJoin(trips(), (i, t) -> t.tripNumber == i.identification)
			.InnerJoin(inbounds(), (i, t, ti) -> ti.tripNumber == t.tripNumber)
			.InnerJoin(drivers(), (i, t, ti, d) -> d.tripNumber == ti.tripNumber)
			.ToExpression();

		assertJoinsOn(select, 1, Inner, "inbounds", "tripNumber", 1, "tripNumber");
		assertJoinsOn(select, 2, Inner, "drivers", "tripNumber", 2, "tripNumber");
	}

	function testRelationshipJoin_OnTwoSourceQuery_ReadsWhicheverSourceTheRelationshipNames() {
		final select = incidents().From()
			.LeftJoin(trips(), (i, t) -> t.tripNumber == i.identification)
			.LeftJoin(MultiTrip.WithInbound)
			.ToExpression();

		assertJoinsOn(select, 1, Left, "inbounds", "tripNumber", 1, "tripNumber");
	}

	function testRelationshipJoin_MatchesExplicitPredicateForm() {
		final targetForm = incidents().From()
			.LeftJoin(trips(), (i, t) -> t.tripNumber == i.identification)
			.LeftJoin(MultiTrip.WithInbound)
			.ToExpression();

		final predicateForm = incidents().From()
			.LeftJoin(trips(), (i, t) -> t.tripNumber == i.identification)
			.LeftJoin(inbounds(), (i, t, ti) -> t.tripNumber == ti.tripNumber)
			.ToExpression();

		assertSameJoins(predicateForm, targetForm);
	}

	function testRelationshipJoin_OnThreeSourceQuery() {
		final select = incidents().From()
			.InnerJoin(trips(), (i, t) -> t.tripNumber == i.identification)
			.InnerJoin(MultiTrip.WithInbound)
			.InnerJoin(MultiInbound.WithDriver)
			.ToExpression();

		assertJoinsOn(select, 1, Inner, "inbounds", "tripNumber", 1, "tripNumber");
		assertJoinsOn(select, 2, Inner, "drivers", "tripNumber", 2, "tripNumber");
	}

	function testRelationshipJoin_RightAndOuter_CarryTheirJoinType() {
		final right = incidents().From()
			.InnerJoin(trips(), (i, t) -> t.tripNumber == i.identification)
			.RightJoin(MultiTrip.WithInbound)
			.ToExpression();

		final outer = incidents().From()
			.InnerJoin(trips(), (i, t) -> t.tripNumber == i.identification)
			.RightJoin(MultiTrip.WithInbound)
			.OuterJoin(MultiInbound.WithDriver)
			.ToExpression();

		assertJoinsOn(right, 1, Right, "inbounds", "tripNumber", 1, "tripNumber");
		assertJoinsOn(outer, 2, Outer, "drivers", "tripNumber", 2, "tripNumber");
	}

	function testCrossJoin_Table_OnMultiSourceQuery() {
		final select = incidents().From()
			.InnerJoin(trips(), (i, t) -> t.tripNumber == i.identification)
			.CrossJoin(inbounds())
			.CrossJoin(drivers())
			.ToExpression();

		Assert.equals(JoinType.Cross, select.join(1).Type);
		Assert.equals("inbounds", select.join(1).Source.tableName());
		Assert.equals(JoinType.Cross, select.join(2).Type);
		Assert.equals("drivers", select.join(2).Source.tableName());
	}
}
