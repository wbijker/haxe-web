package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.migrations.SchemaBuilder;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class NamingCurrencyObject {
	public var type:Int = 1;
	public var zar:Float = 0;
	public var forex:Float = 0;

	public function new() {}
}

@tableName("procurement_job")
class ProcurementJob {
	public var id:Int = 0;
	public var buyerUserId:Int = 0;
	public var dbDeletedFlag:Bool = false;

	/**
		C# registers `Price` → `price` through `EntityColumnNames`, a second authority the table
		builder does not consult. This port has one: the name on the member, read by the schema and
		the query alike.
	**/
	@columnName("price") public var price:NamingCurrencyObject = new NamingCurrencyObject();

	public function new() {}
}

class NamingDb {
	public final Jobs:DbTable<ProcurementJob> = DbTable.of();

	public function new() {}
}

/**
	`Integration/FlattenObjectNamingTests.cs`.

	What an owned object's columns are called when the entity's columns are not called after its
	properties. The C# bug these pin — a registered name and an attribute disagreeing about the
	prefix — cannot arise here, where one rule names a column for the schema and the query both;
	what is pinned instead is that rule: every column a query names is one the table has.
**/
class Integration_FlattenObjectNamingTests extends TestCase {
	static final Database = "needs a database: eval has none (PHP runtime only)";

	static function Sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	/** The columns the table is actually made with — the only names there are to name. */
	static function TableColumns():Array<String> {
		return SchemaBuilder.Of(new NamingDb()).Table("procurement_job").Columns.map(c -> c.Name);
	}

	static function AssertTableHas(column:String, sql:String):Void {
		Assert.contains(column, sql);
		Assert.isTrue(TableColumns().indexOf(column) >= 0, 'The table has no column "$column"; it has ${TableColumns().join(", ")}');
	}

	// ---- what the table calls them ---------------------------------------------------------

	function testTheTableNamesEachFieldAfterThePropertyAndTheField() {
		Assert.isTrue(TableColumns().indexOf("price_type") >= 0);
		Assert.isTrue(TableColumns().indexOf("price_zar") >= 0);
		Assert.isTrue(TableColumns().indexOf("price_forex") >= 0);
	}

	// ---- the five, as they were reported ---------------------------------------------------

	function testAFieldSelected_IsAColumnTheTableHas() {
		final sql = Sql(Query.select(ProcurementJob)
			.Select(r -> {forex: r.price.forex, type: r.price.type, zar: r.price.zar})
			.ToExpression());

		AssertTableHas("price_zar", sql);
		Assert.doesNotContain("Price_Zar", sql);
	}

	function testAFieldSet_IsAColumnTheTableHas() {
		final sql = Sql(new NamingDb().Jobs.Update()
			.Where(r -> r.price.zar > 100)
			.Set(r -> r.price.zar, r -> r.price.zar * 1.15)
			.ToExpression());

		AssertTableHas("price_zar", sql);
		Assert.doesNotContain("Price_Zar", sql);
	}

	function testTheObjectSelected_IsColumnsTheTableHas() {
		final sql = Sql(Query.select(ProcurementJob)
			.Select(r -> {price: r.price, buyerUserId: r.buyerUserId})
			.ToExpression());

		for (column in ["price_type", "price_zar", "price_forex"]) {
			AssertTableHas(column, sql);
		}
		Assert.doesNotContain("Price_Type", sql);
	}

	function testTheObjectSet_IsColumnsTheTableHas() {
		final sql = Sql(new NamingDb().Jobs.Update()
			.Where(r -> r.price.zar > 100)
			.Set(r -> r.price, r -> {
				forex: r.price.forex,
				type: r.price.type,
				zar: r.price.zar * 1.15
			})
			.ToExpression());

		AssertTableHas("price_type", sql);
		Assert.contains("price_type = t0.price_type", sql);
		Assert.doesNotContain("Price_Type", sql);
	}

	function testTheWholeRowRead_IsColumnsTheTableHas() {
		Assert.skip("whole-row SELECT lists every column in C#: this port renders *");
	}

	// ---- and against a database, where the mismatch is an error ------------------------------

	function testAFieldOfIt_IsReadFromTheDatabase() {
		Assert.skip(Database);
	}

	function testAFieldOfIt_IsSetInTheDatabase() {
		Assert.skip(Database);
	}

	function testTheObjectItself_IsReadFromTheDatabase() {
		Assert.skip(Database);
	}

	function testTheObjectItself_IsSetInTheDatabase() {
		Assert.skip(Database);
	}

	function testTheWholeTable_IsRead() {
		Assert.skip(Database);
	}
}
