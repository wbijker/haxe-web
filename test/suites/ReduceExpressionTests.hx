package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("bookings")
class ReduceExprBooking {
	public var id:Int = 0;
	public var unitId:Int = 0;
	public var totalCents:Int = 0;

	public function new() {}
}

@tableName("units")
class ReduceExprUnit {
	public var id:Int = 0;
	public var name:String = "";

	/** A JSON document in C# (`[ColumnObject(Json)]`); JSON is not ported, so here it is one text column. */
	public var listing:String = "";

	/** `[ColumnObject(Flatten)]` — spread over `address_city`. */
	public var address:ReduceExprAddress;

	public function new() {}
}

class ReduceExprAddress {
	public var city:String = "";

	public function new() {}
}

@tableName("owners")
class ReduceExprOwner {
	public var id:Int = 0;
	public var who:String = "";

	public function new() {}
}

/**
	`ReduceExpressionTests.cs`: what a reduce is allowed to name. A row it joined, yes — see
	`ReduceTests` — but also a column, a calculation over one, a field of an owned object: anything
	the query could have selected, under a name of its own.
**/
class ReduceExpressionTests extends TestCase {
	/** The three-way join the reduce examples are written over. */
	static function Joined() {
		return Query.select(ReduceExprBooking)
			.InnerJoin(Query.select(ReduceExprUnit), (b, u) -> b.unitId == u.id)
			.InnerJoin(Query.select(ReduceExprOwner), (b, u, o) -> o.id == u.id);
	}

	// ---- what a reduce may name -------------------------------------------------------------------------

	function testItNamesWhateverTheQueryCouldHaveSelected() {
		// C# reads Column3 out of a JSON document with a fallback; JSON is not ported, so the fallback
		// is over a plain column here and the JSON extraction is the part left out.
		final select = Joined()
			.Reduce((b, u, o) -> {
				Column1: b.id,
				Column2: b.totalCents + 10,
				Column3: Sql.coalesce(u.name, ""),
				Column4: o,
			})
			.ToExpression();

		Assert.equals(["Column1", "Column2", "Column3", "Column4_id", "Column4_who"], select.memberNames());

		final booking = select.tableSource();
		select.columnIn(select.selectionOf("Column1"), "id", booking.Alias);

		final sum = select.selectionOf("Column2").binary(Add);
		select.columnIn(sum.Left, "totalCents", booking.Alias);
		sum.Right.value(10);

		final fallback = select.selectionOf("Column3").call("COALESCE");
		Assert.count(2, fallback.Arguments);
		select.columnIn(fallback.Arguments[0], "name", select.join(0).Source.Alias);
		fallback.Arguments[1].value("");

		select.columnIn(select.selectionOf("Column4_who"), "who", select.join(1).Source.Alias);
	}

	function testWhatFollowsReadsTheNameAndGetsTheCalculation() {
		final select = Joined()
			.Reduce((b, u, o) -> {Total: b.totalCents + 10, u: u})
			.Select(f -> {A: f.Total + 20})
			.ToExpression();

		// ((totalCents + 10) + 20) — the outer sum is over the inner one, not over a column called Total.
		final outer = select.selectionOf("A").binary(Add);
		outer.Right.value(20);

		final inner = outer.Left.binary(Add);
		select.columnIn(inner.Left, "totalCents", select.tableSource().Alias);
		inner.Right.value(10);

		// Still the join it was: the calculation is a projection over the sources, not a query beneath them.
		Assert.equals("bookings", select.selectTableName());
		Assert.equals("units", select.joinedTableName());
	}

	function testANamedCalculationFiltersAndOrdersByWhatItIs() {
		final select = Joined()
			.Reduce((b, u, o) -> {Total: b.totalCents * 2, u: u})
			.Where(f -> f.Total > 100)
			.OrderByDesc(f -> f.Total)
			.ToExpression();

		final booking = select.tableSource();

		final predicate = select.whereBinary(GreaterThan);
		select.columnIn(predicate.Left.binary(Multiply).Left, "totalCents", booking.Alias);
		predicate.Right.value(100);

		Assert.isFalse(select.orderBy().Ascending);
		select.columnIn(select.orderBy().Expression.binary(Multiply).Left, "totalCents", booking.Alias);
	}

	// ---- objects read through a row the reduce named -----------------------------------------------------

	function testAJsonFieldIsReadThroughTheRowThatCarriesIt() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	function testAnOwnedObjectsFieldIsReadThroughTheRowThatCarriesIt() {
		final select = Joined()
			.Reduce((b, u, o) -> {b: b, u: u})
			.Select(x -> {City: x.u.address.city})
			.ToExpression();

		select.columnIn(select.selectionOf("City"), "address_city", select.join().Source.Alias);
	}

	// ---- a row carried further ---------------------------------------------------------------------------

	function testARowCarriedOnKeepsItsColumns() {
		final select = Joined()
			.Reduce((b, u, o) -> {Total: b.totalCents + 1, u: u})
			.Select(f -> {Total: f.Total, Unit: f.u})
			.ToExpression();

		Assert.equals(["Total", "Unit_id", "Unit_name", "Unit_listing", "Unit_address_city"], select.memberNames());

		select.columnIn(select.selectionOf("Unit_name"), "name", select.join().Source.Alias);
	}

	function testARowSelectedOnItsOwnIsItsColumns() {
		final select = Joined()
			.Reduce((b, u, o) -> {b: b, u: u})
			.Select(f -> f.u)
			.ToExpression();

		Assert.equals(["id", "name", "listing", "address_city"], select.memberNames());
		select.columnIn(select.selectionOf("id"), "id", select.join().Source.Alias);
	}

	function testARowCarriedOnIsStillARowToReduceAgain() {
		final select = Query.select(ReduceExprBooking)
			.InnerJoin(Query.select(ReduceExprUnit), (b, u) -> b.unitId == u.id)
			.Reduce((b, u) -> {Total: b.totalCents + 1, u: u})
			.InnerJoin(Query.select(ReduceExprOwner), (f, o) -> o.id == f.u.id)
			.Reduce((f, o) -> {Twice: f.Total * 2, u: f.u, o: o})
			.Where(x -> x.u.name == "Loft")
			.ToExpression();

		final unit = select.join().Source;

		Assert.equals(["Twice", "u_id", "u_name", "u_listing", "u_address_city", "o_id", "o_who"], select.memberNames());

		// The row still names the same source two reduces later.
		select.columnIn(select.selectionOf("u_name"), "name", unit.Alias);
		select.columnIn(select.whereBinary(Equal).Left, "name", unit.Alias);

		// And the calculation the first reduce named is folded into the one the second wrote over it.
		final twice = select.selectionOf("Twice").binary(Multiply);
		select.columnIn(twice.Left.binary(Add).Left, "totalCents", select.tableSource().Alias);
	}

	// ---- what it reads back ------------------------------------------------------------------------------

	function testItReadsBackTheCalculationAndTheRowItCarried() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
