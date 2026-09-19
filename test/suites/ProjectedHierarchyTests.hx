package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("bookings")
class HierBooking {
	public var id:Int = 0;
	public var unitId:Int = 0;
	public var totalCents:Int = 0;

	public function new() {}
}

@tableName("units")
class HierUnit {
	public var id:Int = 0;
	public var name:String = "";

	/** A JSON document in C#; JSON is not ported, so here it is one text column. */
	public var listing:String = "";

	/** `[ColumnObject(Flatten)]` — spread over `address_city`. */
	public var address:HierAddress;

	public function new() {}
}

class HierAddress {
	public var city:String = "";

	public function new() {}
}

/**
	`ProjectedHierarchyTests.cs`: a projection is a tree, and a result set is flat. Whole rows and
	objects built on the spot are flattened into columns named along the way — `Unit_name`,
	`Data_col` — and every column keeps the path that reaches it. C# builds the objects with
	member-init (`new Money { Cents = … }`); here they are structures written in place.
**/
class ProjectedHierarchyTests extends TestCase {
	static function Joined() {
		return Query.select(HierBooking).InnerJoin(Query.select(HierUnit), (b, u) -> b.unitId == u.id);
	}

	// ---- what a projection may name ---------------------------------------------------------------------

	function testAWholeTableIsTheColumnsOfThatTable() {
		final select = Joined()
			.Select((b, u) -> {SomeTable: b, AnotherTable: u})
			.ToExpression();

		final projection = select.projection();

		Assert.equals([
			"SomeTable_id", "SomeTable_unitId", "SomeTable_totalCents",
			"AnotherTable_id", "AnotherTable_name", "AnotherTable_listing", "AnotherTable_address_city",
		], projection.Members.map(m -> m.Name));

		// And each one says where it goes, which is what the name is only a rendering of.
		Assert.equals(["SomeTable", "totalCents"], select.member("SomeTable_totalCents").Path);
		Assert.equals(["AnotherTable", "address", "city"], select.member("AnotherTable_address_city").Path);
	}

	function testAnObjectBuiltInTheProjectionIsItsMembers() {
		final select = Query.select(HierBooking)
			.Select(b -> {
				Data1: {cents: b.totalCents, label: "net"},
				Data2: {inner: {cents: b.id}},
			})
			.ToExpression();

		final projection = select.projection();

		Assert.equals(["Data1_cents", "Data1_label", "Data2_inner_cents"], projection.Members.map(m -> m.Name));

		Assert.equals(["Data2", "inner", "cents"], select.member("Data2_inner_cents").Path);
	}

	function testAReduceNamesTheSameThings() {
		final select = Joined()
			.Reduce((b, u) -> {Data: {cents: b.totalCents}, u: u})
			.ToExpression();

		Assert.equals(["Data_cents", "u_id", "u_name", "u_listing", "u_address_city"], select.memberNames());

		// The same join it was: a reduce is a projection in place, not a query over one.
		Assert.equals("bookings", select.selectTableName());
		Assert.equals("units", select.joinedTableName());
		select.columnIn(select.selectionOf("u_name"), "name", select.join().Source.Alias);
	}

	// ---- reading it back in the statement it belongs to --------------------------------------------------

	function testAReducedPathIsWhatItWasProjectedFrom() {
		final select = Joined()
			.Reduce((b, u) -> {Data: {cents: b.totalCents + 10}, u: u})
			.Where(x -> x.Data.cents > 100)
			.OrderBy(x -> x.u.name)
			.ToExpression();

		final predicate = select.whereBinary(GreaterThan);
		final sum = predicate.Left.binary(Add);
		select.columnIn(sum.Left, "totalCents", select.tableSource().Alias);
		sum.Right.value(10);

		select.columnIn(select.orderBy().Expression, "name", select.join().Source.Alias);
	}

	function testAJsonFieldUnderAReducedRowIsItsOwnersColumn() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	// ---- reading it back over the query that projected it ------------------------------------------------

	function testAPathOverAProjectedQueryIsTheColumnThatQueryExposes() {
		final select = Joined()
			.Select((b, u) -> {Unit: u, Data: {cents: b.totalCents}})
			.Where(x -> x.Unit.name == "Loft" && x.Data.cents > 3)
			.ToExpression();

		final beneath = select.Source;

		final and = select.whereBinary(And);
		select.columnIn(and.Left.binary(Equal).Left, "Unit_name", beneath.Alias);
		select.columnIn(and.Right.binary(GreaterThan).Left, "Data_cents", beneath.Alias);
	}

	function testAnObjectUnderACarriedRowIsReadOffTheColumnThatQueryExposes() {
		// The C# test first reads a JSON field under the carried row; JSON is not ported, so that
		// half is left out and the owned object — which has no column of its own at all — is what
		// is checked: its field was exposed under the whole path.
		final owned = Joined()
			.Select((b, u) -> {Unit: u})
			.Where(x -> x.Unit.address.city == "Knysna")
			.ToExpression();

		owned.columnIn(owned.whereBinary(Equal).Left, "Unit_address_city", owned.Source.Alias);
	}

	function testAPathSurvivesASecondProjection() {
		final select = Joined()
			.Select((b, u) -> {Unit: u, Total: b.totalCents + 1})
			.Select(x -> {name: x.Unit.name, Doubled: x.Total * 2})
			.ToExpression();

		// Each member of the outer projection reads a column the inner one exposed, found by its path.
		select.columnIn(select.selectionOf("name"), "Unit_name", select.Source.Alias);
		select.columnIn(select.selectionOf("Doubled").binary(Multiply).Left, "Total", select.Source.Alias);
	}

	// ---- what it reads back ------------------------------------------------------------------------------

	function testTheAnswerComesBackInTheShapeItWasAskedFor() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testTheShapeSurvivesBeingFilteredAndProjectedAgain() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testARowThatWasNotThereIsNull() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
