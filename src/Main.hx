import codequery.sqldrivers.SqlDriver;

class Main {
	static function main() {
		final db = new SampleDb();
		final driver = new SqlDriver();

		// The line this step is for. The predicate never becomes a closure: it is converted to a
		// SQL expression tree while compiling.
		final query = db.Deliveries.From().Where(a -> a.id == 12);
		Sys.println(driver.ToSql(query.ToExpression()));
	}
}
