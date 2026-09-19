package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.migrations.SchemaBuilder;
import codequery.migrations.SchemaChange;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class OwnedAddress {
	public var street:String = "";
	public var city:String = "";
	public var postalCode:Int = 0;

	public function new() {}
}

@tableName("customers")
class OwnedCustomer {
	public var id:Int = 0;
	public var name:String = "";

	/** `[ColumnObject(Flatten)]` — a member that is an object is flattened, which is the port's one object kind. */
	public var shippingAddress:OwnedAddress;

	public function new() {}
}

class OwnedShop {
	public final Customers:DbTable<OwnedCustomer> = DbTable.of();

	public function new() {}
}

/**
	`OwnedTypeTests.cs`: owned types — the object is flattened into individual `{member}_{field}`
	columns on the parent table, in the schema, queries, inserts and fetches. The C# file's second
	class, `OwnedTypeBindingTests`, is the last test here.
**/
class OwnedTypeTests extends TestCase {
	function testSchema_FlattensOwnedIntoColumns() {
		final table = SchemaBuilder.Of(new OwnedShop()).Table("customers");
		final names = table.Columns.map(c -> c.Name);

		Assert.isTrue(names.indexOf("shippingAddress_street") >= 0);
		Assert.isTrue(names.indexOf("shippingAddress_city") >= 0);
		Assert.isTrue(names.indexOf("shippingAddress_postalCode") >= 0);
		Assert.isTrue(names.indexOf("shippingAddress") < 0); // no single object column
	}

	function testCreateTable_HasFlattenedColumns_AndScalarTypes() {
		final table = SchemaBuilder.Of(new OwnedShop()).Table("customers");
		final sql = new SqlTranslator().ToDdl(CreateTable(table));

		Assert.contains("shippingAddress_street TEXT", sql);
		Assert.contains("shippingAddress_postalCode INTEGER", sql);
	}

	function testQuery_OwnedMemberAccess_ResolvesToFlattenedColumn() {
		final select = Query.select(OwnedCustomer).Where(c -> c.shippingAddress.city == "Cape Town").ToExpression();

		select.whereClause().comparison("shippingAddress_city", Equal, "Cape Town");
	}

	// ---- OwnedTypeBindingTests ------------------------------------------------------------------------

	function testInsert_And_Fetch_RoundTripsOwnedColumns() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
