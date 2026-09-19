import codequery.sqldrivers.SqlDriver;
import codequery.sqlexpressions.NullsOrdering;

class Main {
	// Built during static initialisation, which is what catches a generated column that is not
	// ready in time: this type is generated before the columns are.
	static final db = new SampleDb();
	static final driver = new SqlDriver();

	static function main() {
		// A lambda's parameter names a row by position, so a column knows which source it belongs
		// to without the statement having to be built first.
		show(db.Deliveries.From().Where(a -> a.id == 12));

		show(db.Deliveries.From()
			.Where(a -> a.status == 6)
			.OrderBy(a -> a.noteNo)
			.OrderByDesc(a -> a.id)
			.Limit(10)
			.Offset(20));

		show(db.Deliveries.From()
			.Distinct(a -> a.fromStoreId)
			.OrderBy(a -> a.fromStoreId, NullsOrdering.Last));

		// Joining a table: the condition is written over both rows, in the order they were joined.
		show2(db.Deliveries.From()
			.InnerJoin(db.Lines, (d, l) -> d.id == l.deliveryId)
			.Where((d, l) -> l.quantity > 0)
			.OrderBy((d, l) -> l.itemCode));

		// A table joined to itself: two sources, so the same column has to render two ways.
		show2(db.Deliveries.From()
			.LeftJoin(db.Deliveries, (a, b) -> a.purchaseOrderId == b.purchaseOrderId && a.id != b.id));

		// Joining a query rather than a table puts it in as a subquery.
		show2(db.Deliveries.From()
			.InnerJoin(db.Lines.From().Where(l -> l.quantity > 100), (d, l) -> d.id == l.deliveryId));

		show2(db.Deliveries.From().CrossJoin(db.Lines));

		// Joining on: each join adds a row, and every lambda after it takes one more parameter.
		Sys.println("");
		Sys.println(driver.ToSql(db.Deliveries.From()
			.InnerJoin(db.Lines, (d, l) -> d.id == l.deliveryId)
			.InnerJoin(db.Stores, (d, l, s) -> d.fromStoreId == s.id)
			.Where((d, l, s) -> s.code == "JHB")
			.ToExpression()));

		Sys.println(driver.ToSql(db.Deliveries.From()
			.InnerJoin(db.Lines, (d, l) -> d.id == l.deliveryId)
			.InnerJoin(db.Stores, (d, l, from) -> d.fromStoreId == from.id)
			.LeftJoin(db.Stores, (d, l, from, to) -> d.toStoreId == to.id)
			.Where((d, l, from, to) -> from.code != to.code && l.quantity > 0)
			.OrderBy((d, l, from, to) -> to.name)
			.Limit(50)
			.ToExpression()));

		// Counting. A query that counts what it reads selects COUNT(*) in place of its rows.
		Sys.println("");
		Sys.println(driver.ToSql(db.Deliveries.From().Where(a -> a.id > 12).OrderBy(a -> a.id).CountExpression()));
		// One narrowed by DISTINCT or a limit has to be counted from the outside.
		Sys.println(driver.ToSql(db.Deliveries.From().Distinct(a -> a.fromStoreId).CountExpression()));
		Sys.println(driver.ToSql(db.Deliveries.From().Limit(10).CountExpression()));

		// Projection: a structure names each member, and the query carries that shape from here on.
		Sys.println("");
		Sys.println(driver.ToSql(db.Deliveries.From()
			.Where(a -> a.status == 6)
			.Select(a -> {store: a.fromStoreId, note: a.noteNo})
			.ToExpression()));

		// Reduce: naming a row selects that row's columns and keeps its type.
		Sys.println(driver.ToSql(db.Deliveries.From()
			.InnerJoin(db.Lines, (d, l) -> d.id == l.deliveryId)
			.Reduce((d, l) -> l)
			.ToExpression()));

		// GROUP BY, with the aggregates of each group.
		Sys.println(driver.ToSql(db.Lines.From()
			.GroupBy(a -> a.deliveryId)
			.Having(a -> a.quantity > 0)
			.SelectAggregation(a -> {lines: a.count(), units: a.sum(r -> r.quantity), kinds: a.countDistinct(r -> r.itemCode)})
			.ToExpression()));

		// A window arrives as an extra row, which is how the projection names it.
		Sys.println(driver.ToSql(db.Lines.From()
			.Window(w -> w.PartitionBy(a -> a.deliveryId).OrderBy(a -> a.id))
			.SelectAggregation((a, w) -> {running: a.sum(r -> r.quantity).over(w)})
			.ToExpression()));

		// EXISTS, correlated with the outer row.
		Sys.println(driver.ToSql(db.Deliveries.From()
			.WhereExists(db.Lines, (d, l) -> l.deliveryId == d.id && l.quantity > 0)
			.ToExpression()));

		Sys.println(driver.ToSql(db.Deliveries.From()
			.WhereNotExists(db.Lines, (d, l) -> l.deliveryId == d.id)
			.ToExpression()));

		Sys.println("");
		try {
			db.Deliveries.From().Count();
		} catch (e:String) {
			Sys.println('Count(): $e');
		}
	}

	static function show(query:codequery.queries.ISelectQuery<model.Delivery>) {
		Sys.println(driver.ToSql(query.ToExpression()));
	}

	static function show2<A, B>(query:codequery.queries.ISelectQuery2<A, B>) {
		Sys.println(driver.ToSql(query.ToExpression()));
	}
}
