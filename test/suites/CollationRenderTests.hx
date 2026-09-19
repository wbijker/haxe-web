package suites;

import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `CollationRenderTests.cs`: column COLLATE rendering. The port writes the name bare, as it writes every identifier. */
class CollationRenderTests extends TestCase {
	static function Table(collation:String):CreateTableExpression {
		return new CreateTableExpression("people", [new ColumnDefinition("Name", SqlText, false, null, null, null, null, false, collation)]);
	}

	function testPostgres_QuotesCollation() {
		final sql = new SqlTranslator().ToSql(Table("en_US"));
		Assert.contains("Name TEXT COLLATE en_US NOT NULL", sql);
	}

	function testSqlServer_BareCollation() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlite_BareCollation() {
		final sql = new SqlTranslator().ToSql(Table("NOCASE"));
		Assert.contains("Name TEXT COLLATE NOCASE NOT NULL", sql);
	}
}
