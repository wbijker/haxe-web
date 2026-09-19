package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class BuiltCost {
	public var amount:Float = 0;
	public var currency:String = "";

	public function new() {}
}

/** C#'s `Priced`, a typed row: here a structure the projection is checked against. */
typedef BuiltPriced = {name:String, cost:{amount:Float, currency:String}};

@tableName("built_parts")
class BuiltPart {
	public var id:Int = 0;
	public var name:String = "";
	public var price:Float = 0;
	public var factor:Float = 0;

	public function new() {}
}

/**
	`Integration/ConstructedObjectTests.cs`.

	Objects built by the projection rather than read from a column — `{cost: {amount: r.price,
	currency: "ZAR"}}`. There is no column for an object the query invents, so each of its members
	is selected under a name carrying the object's — `cost_amount`, `cost_currency` — the same names
	a flattened object's columns take, so one rule reads both.

	A projected query renders as a query over its projection here (`SELECT * FROM (…) AS t0`), so
	the tests look for the projection inside it.
**/
class Integration_ConstructedObjectTests extends TestCase {
	static final Database = "needs a database: eval has none (PHP runtime only)";

	static function Sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	// ---- what it selects ---------------------------------------------------------------------

	function testAnObjectBuiltInTheProjection_SelectsItsMembersUnderItsName() {
		Assert.contains(
			"SELECT t0.name AS name, t0.price AS cost_amount, 'ZAR' AS cost_currency FROM built_parts AS t0",
			Sql(Query.select(BuiltPart)
				.Select(r -> {name: r.name, cost: {amount: r.price, currency: "ZAR"}})
				.ToExpression()));
	}

	function testAnObjectBuiltInsideOne_CarriesBothNames() {
		Assert.contains(
			"SELECT t0.price AS money_amount, 'ZAR' AS money_rate_symbol, t0.factor AS money_rate_factor FROM built_parts AS t0",
			Sql(Query.select(BuiltPart)
				.Select(r -> {
					money: {
						amount: r.price,
						rate: {symbol: "ZAR", factor: r.factor}
					}
				})
				.ToExpression()));
	}

	function testAnObjectBuiltIntoATypedRow_SelectsTheSameWay() {
		Assert.contains(
			"t0.price AS cost_amount",
			Sql(Query.select(BuiltPart)
				.Select(r -> ({name: r.name, cost: {amount: r.price, currency: "ZAR"}} : BuiltPriced))
				.ToExpression()));
	}

	// ---- what comes back ---------------------------------------------------------------------

	function testAnObjectBuiltInTheProjection_IsPutTogetherFromThoseColumns() {
		Assert.skip(Database);
	}

	function testAnObjectBuiltIntoATypedRow_IsPutTogetherToo() {
		Assert.skip(Database);
	}

	function testAnObjectBuiltInsideOne_IsPutTogetherAtBothLevels() {
		Assert.skip(Database);
	}

	function testAnObjectBuiltFromNothingButValues_StillComesBack() {
		Assert.skip(Database);
	}
}
