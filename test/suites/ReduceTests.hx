package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("bookings")
class ReduceBooking {
	public var id:Int = 0;
	public var unitId:Int = 0;
	public var totalCents:Int = 0;

	public function new() {}
}

@tableName("units")
class ReduceUnit {
	public var id:Int = 0;
	public var name:String = "";
	public var sleeps:Int = 0;

	public function new() {}
}

/**
	`ReduceTests.cs`: `reduce` — folding a joined query back to one row. A join widens the query, and
	by the third or fourth source every later clause is written with parameters it does not use;
	reducing names the sources once and hands back a single-row query whose row carries them.
**/
class ReduceTests extends TestCase {
	// ---- what it builds --------------------------------------------------------------------------------

	function testItProjectsTheRowsUnderTheirMembers() {
		final select = Query.select(ReduceBooking)
			.InnerJoin(Query.select(ReduceUnit), (b, u) -> b.unitId == u.id, (b, u) -> {b: b, u: u})
			.ToExpression();

		Assert.equals(["b_id", "b_unitId", "b_totalCents", "u_id", "u_name", "u_sleeps"], select.memberNames());

		// Both rows' columns come from the sources of this statement, not from a subquery over them.
		final booking = select.tableSource();
		Assert.equals("bookings", booking.Table.Name);
		select.columnIn(select.selectionOf("b_id"), "id", booking.Alias);

		final unit = select.joinOfType(Inner).Source;
		Assert.equals("units", unit.tableName());
		select.columnIn(select.selectionOf("u_id"), "id", unit.Alias);

		select.join().On.columnComparison("unitId", Equal, "id");
	}

	function testTheReducedRowIsReadThroughAfterwards() {
		final select = Query.select(ReduceBooking)
			.InnerJoin(Query.select(ReduceUnit), (b, u) -> b.unitId == u.id, (b, u) -> {b: b, u: u})
			.Where(x -> x.u.sleeps >= 4 && x.b.totalCents > 0)
			.OrderByDesc(x -> x.b.totalCents)
			.ToExpression();

		// Still the same join, not a subquery over one.
		final booking = select.tableSource();
		final unit = select.join().Source;

		final and = select.whereBinary(And);
		select.columnIn(and.Left.binary(GreaterThanOrEqual).Left, "sleeps", unit.Alias);
		select.columnIn(and.Right.binary(GreaterThan).Left, "totalCents", booking.Alias);

		Assert.isFalse(select.orderBy().Ascending);
		select.columnIn(select.orderBy().Expression, "totalCents", booking.Alias);
	}

	function testReduceIsAlsoAStepOfItsOwn() {
		final atTheJoin = Query.select(ReduceBooking)
			.InnerJoin(Query.select(ReduceUnit), (b, u) -> b.unitId == u.id, (b, u) -> {b: b, u: u})
			.ToExpression();

		final afterwards = Query.select(ReduceBooking)
			.InnerJoin(Query.select(ReduceUnit), (b, u) -> b.unitId == u.id)
			.Reduce((b, u) -> {b: b, u: u})
			.ToExpression();

		Assert.equals(atTheJoin.memberNames(), afterwards.memberNames());
		Assert.equals(atTheJoin.selectTableName(), afterwards.selectTableName());
		Assert.equals(atTheJoin.joinedTableName(), afterwards.joinedTableName());

		// The columns each member selects are the same columns of the same sources.
		for (name in atTheJoin.memberNames()) {
			final expected = atTheJoin.selectionOf(name).column();
			afterwards.columnIn(afterwards.selectionOf(name), expected.ColumnName,
				atTheJoin.sourceOf(atTheJoin.selectionOf(name)).Alias);
		}
	}

	function testItCarriesValuesAsWellAsRows() {
		final select = Query.select(ReduceBooking)
			.InnerJoin(Query.select(ReduceUnit), (b, u) -> b.unitId == u.id, (b, u) -> {b: b, name: u.name})
			.Where(x -> x.name == "Loft")
			.ToExpression();

		// The member is named after the column, so it keeps the column's own name.
		final unit = select.join().Source;
		select.columnIn(select.selectionOf("name"), "name", unit.Alias);

		final predicate = select.whereBinary(Equal);
		select.columnIn(predicate.Left, "name", unit.Alias);
		predicate.Right.value("Loft");
	}

	function testItReducesTheWiderJoinsToo() {
		final select = Query.select(ReduceBooking)
			.InnerJoin(Query.select(ReduceUnit), (b, u) -> b.unitId == u.id)
			.InnerJoin(Query.select(ReduceUnit), (b, u, u2) -> u2.id == b.unitId)
			.Reduce((b, u, u2) -> {b: b, u: u, other: u2})
			.Where(x -> x.other.sleeps > 1)
			.ToExpression();

		final second = select.join(1).Source;
		select.columnIn(select.selectionOf("other_sleeps"), "sleeps", second.Alias);

		final predicate = select.whereBinary(GreaterThan);
		select.columnIn(predicate.Left, "sleeps", second.Alias);
		predicate.Right.value(1);
	}

	function testSomethingThatIsNotARowIsRefused() {
		final error = Assert.throwsMessage(() -> Query.select(ReduceBooking)
			.InnerJoin(Query.select(ReduceUnit), (b, u) -> b.unitId == u.id)
			.Reduce((b, u) -> b.id));

		Assert.contains("builds a row from the sources it joins", error);
	}

	// ---- what it reads back ----------------------------------------------------------------------------

	function testTheRowsComeBackWhole() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testTheReducedQueryStillFilters() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
