import codequery.sqldrivers.SqlDriver;
import codequery.sqlexpressions.NullsOrdering;

class Main {
	// Built during static initialisation, which is what catches a generated column that is not
	// ready in time: this type is generated before the columns are.
	static final db = new SampleDb();
	static final driver = new SqlDriver();

	static function main() {
		// The predicate never becomes a closure: it is converted to a SQL expression tree while
		// compiling, and its columns resolve to the generated statics.
		show(db.Deliveries.From().Where(a -> a.id == 12));

		// Every clause answers with a query of its own, so they chain.
		show(db.Deliveries.From()
			.Where(a -> a.status == 6)
			.Where(a -> a.noteNo != "")
			.OrderBy(a -> a.noteNo)
			.OrderByDesc(a -> a.id)
			.Limit(10)
			.Offset(20));

		// DISTINCT, and DISTINCT ON a composite key.
		show(db.Deliveries.From().Distinct().OrderBy(a -> a.id));
		show(db.Deliveries.From()
			.Distinct(a -> a.fromStoreId)
			.Distinct(a -> a.toStoreId)
			.OrderBy(a -> a.fromStoreId, NullsOrdering.Last)
			.OrderByDesc(a -> a.id, NullsOrdering.First));

		// Ties and percentages cannot be said with LIMIT, so they are rendered the long way.
		show(db.Deliveries.From().OrderByDesc(a -> a.id).Limit(5).WithTies());
		show(db.Deliveries.From().OrderBy(a -> a.id).Limit(10).Offset(100).Percent());
	}

	static function show(query:codequery.queries.ISelectQuery<model.Delivery>) {
		Sys.println(driver.ToSql(query.ToExpression()));
	}
}
