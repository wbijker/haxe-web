package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.QualifiedTableName;
import codequery.RowShape;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("shaped_parts")
class ShapedPart {
	public var id:Int = 0;
	public var name:String = "";
	public var price:Float = 0;

	@columnObject("Flatten")
	public var cost:ShapedMoney = new ShapedMoney();

	public function new() {}
}

class ShapedMoney {
	public var amount:Float = 0;

	@columnName("ccy")
	public var currency:String = "";

	public function new() {}
}

/**
	The clauses as callbacks, and the rows a query hands back — this port's own: the C# converts
	an expression tree at runtime, where here a lambda compiles to a callback over the rows'
	columns, and what it answers with is flattened when the query runs.
**/
class RowShapeTests extends TestCase {
	// ---- what a callback answers with -----------------------------------------------------------------

	function testAStructureIsSelectedInTheOrderItWasWritten() {
		final select = Query.select(ShapedPart).Select(p -> {label: p.name, key: p.id, data: {cents: p.price}}).ToExpression();
		Assert.equals(["label", "key", "data_cents"], select.memberNames());
	}

	function testAWholeRowIsAllItsColumns() {
		final select = Query.select(ShapedPart).Select(p -> p).ToExpression();
		Assert.isType(select.Selection, AllColumnsSqlExpression);
	}

	function testAnObjectFlattenedIntoTheRowIsItsOwnColumnsUnderTheirOwnNames() {
		final select = Query.select(ShapedPart).Select(p -> p.cost).ToExpression();
		Assert.equals(["amount", "ccy"], select.memberNames());
		select.columnIn(select.selectionOf("amount"), "cost_amount", select.tableSource().Alias);
	}

	function testARowNamedInsideAStructureIsSpreadUnderItsMember() {
		final select = Query.select(ShapedPart)
			.InnerJoin(Query.select(ShapedPart), (a, b) -> a.id == b.id)
			.Select((a, b) -> {left: a.id, right: b})
			.ToExpression();
		Assert.equals(["left", "right_id", "right_name", "right_price", "right_cost_amount", "right_cost_ccy"], select.memberNames());
	}

	function testTheColumnsAProjectionHandsOnAreNamedAsItNamedThem() {
		// After a projection the callback's parameter is the structure it built, its members
		// columns of the projected source — and an object within it is reached as it was written.
		final select = Query.select(ShapedPart)
			.Select(p -> {money: p.cost, key: p.id})
			.Where(r -> r.money.amount > 10 && r.key > 0)
			.ToExpression();
		final and = select.whereBinary(And);
		Assert.equals("money_amount", and.Left.binary(GreaterThan).Left.column().ColumnName);
		Assert.equals("key", and.Right.binary(GreaterThan).Left.column().ColumnName);
	}

	// ---- what a fetched row is read back as -----------------------------------------------------------

	function testAProjectedRowIsReadBackAsItsStructureWithEachValueAsItsType() {
		final query:codequery.queries.SelectQueryImpl = cast Query.select(ShapedPart).Select(p -> {label: p.name, key: p.id, data: {cents: p.price}});
		final row:Dynamic = query.Rows[0].Read(["label" => "bolt", "key" => "12", "data_cents" => "2.5"]);
		Assert.equals("bolt", row.label);
		Assert.equals(12, row.key);
		Assert.isTrue(Std.isOfType(row.key, Int));
		Assert.equals(2.5, row.data.cents);
	}

	function testAnEntityIsReadBackWithItsFlattenedObjectRebuilt() {
		final part:ShapedPart = Query.table(ShapedPart).Shape.Read([
			"id" => "7", "name" => "nut", "price" => "0.25", "cost_amount" => "0.2", "cost_ccy" => "ZAR"
		]);
		Assert.isType(part, ShapedPart);
		Assert.equals(7, part.id);
		Assert.equals("nut", part.name);
		Assert.equals(0.25, part.price);
		Assert.equals(0.2, part.cost.amount);
		Assert.equals("ZAR", part.cost.currency);
	}

	function testALoneValueIsReadBackAsTheValue() {
		final query:codequery.queries.SelectQueryImpl = cast Query.select(ShapedPart).Select(p -> p.id);
		Assert.equals(3, query.Rows[0].Read(["id" => "3"]));
	}

	function testAnArithmeticIsReadBackByItsOperandsType() {
		final query:codequery.queries.SelectQueryImpl = cast Query.select(ShapedPart).Select(p -> {sum: p.id + p.id});
		final row:Dynamic = query.Rows[0].Read(["sum" => "6"]);
		Assert.isTrue(Std.isOfType(row.sum, Int));
	}

	// ---- a table that never learned its shape ---------------------------------------------------------

	function testATableMadeByHandCannotHandALambdaItsColumns() {
		final table = new DbTable<ShapedPart>(new QualifiedTableName("shaped_parts"));
		final message = Assert.throwsMessage(() -> table.From().Where(p -> p.id > 0));
		Assert.contains("DbTable.of()", message);
		Assert.contains("Query.table(T)", message);
	}
}
