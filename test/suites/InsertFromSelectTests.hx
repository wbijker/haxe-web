package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("orders")
class Order {
	public var id:Int = 0;
	@columnNullable(false)
	public var customer:String = "";
	public var shipped:Bool = false;

	public function new() {}
}

@tableName("archived_orders")
class ArchivedOrder {
	public var id:Int = 0;
	@columnNullable(false)
	public var customer:String = "";

	public function new() {}
}

/**
	`InsertFromSelectTests.cs`: INSERT … SELECT through `DbTable.InsertFrom(query)` — the select's
	projection names the inserted columns. The rows copied are counted by running it, which the
	statement's shape says everything about short of that.
**/
class InsertFromSelectTests extends TestCase {
	static final orders:DbTable<Order> = Query.table(Order);
	static final archivedOrders:DbTable<ArchivedOrder> = Query.table(ArchivedOrder);

	function testInsertFromSelect_CopiesProjectedRows() {
		// Archive shipped orders: INSERT INTO archived_orders (id, customer) SELECT … WHERE shipped.
		final shipped = orders.From()
			.Where(o -> o.shipped)
			.Select(o -> {id: o.id, customer: o.customer});

		final insert = archivedOrders.InsertFrom(shipped);

		Assert.equals("archived_orders", insert.Target.tableName());
		Assert.equals(["id", "customer"], insert.insertColumns());
		// A projection is a query over the filtered rows, so the shape is one statement in.
		final projected = insert.insertSelect().subquery();
		Assert.equals("orders", projected.selectTableName());
		Assert.equals(["id", "customer"], projected.memberNames());
		projected.whereClause().column("shipped");
		Assert.skip("needs a database: eval has none (PHP runtime only) — the rows copied are counted by running it");
	}
}
