package suites;

import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DropCascadeTests.cs`: CASCADE on DROP, as PostgreSQL renders it. */
class DropCascadeTests extends TestCase {
	static function Sql(op:SchemaChangeExpression):String {
		return new SqlTranslator().ToSql(op);
	}

	function testPostgres_EmitsCascade_OnEveryDropKind() {
		Assert.equals("DROP TABLE Book CASCADE", Sql(new DropTableExpression("Book", null, false, true)));
		Assert.equals("ALTER TABLE Book DROP COLUMN Meta CASCADE", Sql(new DropColumnExpression("Book", "Meta", null, true)));
		Assert.equals("ALTER TABLE Book DROP CONSTRAINT FK_Book_Author CASCADE", Sql(new DropConstraintExpression("Book", "FK_Book_Author", null, true)));
		Assert.equals("DROP INDEX IX_Book_Title CASCADE", Sql(new DropIndexExpression("Book", "IX_Book_Title", null, false, true)));
		Assert.equals("DROP TYPE BookMeta CASCADE", Sql(new DropTypeExpression("BookMeta", null, false, false, true)));
		Assert.equals("DROP VIEW IF EXISTS BigBooks CASCADE", Sql(new DropRoutineExpression(View, "BigBooks", null, true)));
	}

	function testPostgres_OmitsCascade_WhenNotRequested() {
		Assert.equals("DROP TABLE Book", Sql(new DropTableExpression("Book", null, false, false)));
	}

	function testSqlServer_And_Sqlite_And_MySql_OmitCascade_EvenWhenRequested() {
		Assert.skip("MssqlSqlDriver/SqliteSqlDriver/MySqlSqlDriver: no other dialects in this port");
	}
}
