package suites;

import codequery.migrations.SchemaInspector;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("clus")
class ClusteredEntity {
	@:index("IX_clus_key", clustered = true) public var key:Int = 0;

	public function new() {}
}

/** `IndexDialectTests.cs`: partial (WHERE) and IF NOT EXISTS guards; the one dialect this port renders. */
class IndexDialectTests extends TestCase {
	static function Index(ifNotExists:Bool = false, ?filter:String):CreateIndexExpression {
		return new CreateIndexExpression("products", "IX_products_sku", [new IndexColumnDefinition("Sku", false)], false, false, filter,
			null, ifNotExists);
	}

	static function ClusteredIndex():CreateIndexExpression {
		return new CreateIndexExpression("products", "IX_products_id", [new IndexColumnDefinition("Id", false)], false, true, null, null, false);
	}

	function testPartialIndex_SupportedOnPostgresAndSqlServerAndSqlite() {
		// The port's one dialect renders it; SQL Server's and SQLite's spellings are theirs.
		Assert.contains("WHERE", new SqlTranslator().ToSql(Index(false, "Sku IS NOT NULL")));
	}

	function testPartialIndex_ThrowsOnMySql() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testIfNotExists_SupportedOnPostgresAndSqlite() {
		Assert.contains("IF NOT EXISTS", new SqlTranslator().ToSql(Index(true)));
	}

	function testIfNotExists_ThrowsOnMySqlAndSqlServer() {
		Assert.skip("MySqlSqlDriver/MssqlSqlDriver: no MySQL or SQL Server dialect in this port");
	}

	function testClustered_RendersOnSqlServerOnly() {
		// No clustered syntax on CREATE INDEX here — the flag is ignored, not emitted.
		Assert.doesNotContain("CLUSTERED", new SqlTranslator().ToSql(ClusteredIndex()));
	}

	function testClustered_FromAttribute_RendersOnSqlServer() {
		final idx = Assert.single([
			for (e in SchemaInspector.FromType(ClusteredEntity).Diff(null))
				if (Std.isOfType(e, CreateIndexExpression)) (cast e : CreateIndexExpression)
		]);
		Assert.isTrue(idx.IsClustered);
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port (CREATE CLUSTERED INDEX)");
	}

	function testPlainIndex_WorksEverywhere() {
		final sql = new SqlTranslator().ToSql(Index());
		Assert.contains("CREATE INDEX", sql);
		Assert.doesNotContain("WHERE", sql);
		Assert.doesNotContain("IF NOT EXISTS", sql);
	}
}
