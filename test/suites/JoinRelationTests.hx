package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;
using codequery.testing.SourceAccess;

@tableName("booking")
class RelBooking {
	public var id:Int = 0;
	public var unitId:Int = 0;
	public var guestId:Int = 0;

	public function new() {}

	public static function WithUnit():(RelBooking, RelUnit) -> Bool {
		return (b, u) -> u.id == b.unitId;
	}

	public static function WithGuest():(RelBooking, RelGuest) -> Bool {
		return (b, g) -> g.id == b.guestId;
	}

	/** A relationship that says more than a key — still one predicate. */
	public static function WithNamedUnit(name:String):(RelBooking, RelUnit) -> Bool {
		return (b, u) -> u.id == b.unitId && u.name == name;
	}
}

@tableName("unit")
class RelUnit {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

@tableName("guest")
class RelGuest {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

/**
	`JoinRelationTests.cs` — a relationship named on the entity that has it, so a query says which
	relationship it wants rather than repeating the predicate. C#'s `Join<T>` is a function here
	answering with the condition; the row it reads is the query's row of that type.
**/
class JoinRelationTests extends TestCase {
	static function bookings():DbTable<RelBooking> {
		return Query.table(RelBooking);
	}

	static function units():DbTable<RelUnit> {
		return Query.table(RelUnit);
	}

	static function guests():DbTable<RelGuest> {
		return Query.table(RelGuest);
	}

	/** The join at `index` matches the target's column against the outer row's. */
	static function assertRelated(select:SelectExpression, index:Int, target:String, outer:String):Void {
		final join = select.join(index);
		final on = join.On.binary(Equal);

		on.Left.column(target);
		Assert.equals(join.Source.Alias, select.sourceAlias(on.Left));
		on.Right.column(outer);
		Assert.equals(select.Source.Alias, select.sourceAlias(on.Right));
	}

	function testARelationshipJoinsWhatItNames() {
		final select = bookings().From()
			.InnerJoin(RelBooking.WithUnit)
			.InnerJoin(RelBooking.WithGuest)
			.ToExpression();

		Assert.equals("booking", select.selectTableName());
		Assert.equals(["unit", "guest"], [for (i in 0...2) select.joinedTableName(i)]);

		assertRelated(select, 0, "id", "unitId");
		assertRelated(select, 1, "id", "guestId");
	}

	function testItIsTheJoinWrittenOut() {
		final named = bookings().From()
			.InnerJoin(RelBooking.WithUnit)
			.InnerJoin(RelBooking.WithGuest)
			.Select((b, u, g) -> {id: b.id, unit: u.name, guest: g.name})
			.ToExpression();

		final written = bookings().From()
			.InnerJoin(units(), (b, u) -> u.id == b.unitId)
			.InnerJoin(guests(), (b, u, g) -> g.id == b.guestId)
			.Select((b, u, g) -> {id: b.id, unit: u.name, guest: g.name})
			.ToExpression();

		Assert.equals(new SqlTranslator().ToSql(written), new SqlTranslator().ToSql(named));
	}

	function testTheRowItReadsIsTheOuterRow() {
		final select = bookings().From().InnerJoin(RelBooking.WithUnit).ToExpression();
		final on = select.join().On.binary(Equal);

		on.Left.column("id");
		Assert.equals(select.join().Source.Alias, select.sourceAlias(on.Left));
		on.Right.column("unitId");
		Assert.equals(select.Source.Alias, select.sourceAlias(on.Right));
	}

	function testARelationshipCanSayMoreThanAKey() {
		final wanted = "loft";

		final select = bookings().From().InnerJoin(RelBooking.WithNamedUnit(wanted)).ToExpression();
		final on = select.join().On.binary(And);

		on.Left.binary(Equal);
		final named = on.Right.binary(Equal);
		named.Left.column("name");
		Assert.equals(select.join().Source.Alias, select.sourceAlias(named.Left));
		named.Right.value("loft");
	}

	function testEveryJoinKindTakesOne() {
		Assert.equals(JoinType.Left, bookings().From().LeftJoin(RelBooking.WithUnit).ToExpression().join().Type);
		Assert.equals(JoinType.Right, bookings().From().RightJoin(RelBooking.WithUnit).ToExpression().join().Type);
		Assert.equals(JoinType.Outer, bookings().From().OuterJoin(RelBooking.WithUnit).ToExpression().join().Type);
	}

	function testAWiderQueryNamesTheRowOrLeavesItOut() {
		// C# may spell out the rows the relationship hangs off — `(b, u) => Booking.WithGuest(b)` —
		// or leave them out. Here a relationship names its row by type, so the two are one spelling:
		// the relationship on the row the query started from reads it however many joins have
		// happened since.
		final spelled = bookings().From()
			.InnerJoin(RelBooking.WithUnit)
			.InnerJoin(RelBooking.WithGuest)
			.ToExpression();

		final shorthand = bookings().From()
			.InnerJoin(RelBooking.WithUnit)
			.InnerJoin(RelBooking.WithGuest)
			.ToExpression();

		Assert.equals(new SqlTranslator().ToSql(spelled), new SqlTranslator().ToSql(shorthand));
		assertRelated(shorthand, 1, "id", "guestId");
	}

	function testARelationshipThatReadsTheRowTooEarlyIsRefused() {
		Assert.skip("JoinRelation guard: a relationship here is a lambda read while compiling, so there is no row to read too early");
	}

	function testItReturnsTheJoinedRows() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
