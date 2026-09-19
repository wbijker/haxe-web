package suites;

import codequery.QualifiedTableName;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `ReturningTests.cs`: UPDATE/DELETE … RETURNING, and the dialects that spell it otherwise or not at all. */
class ReturningTests extends TestCase {
	static function DeleteWithReturning():DeleteExpression {
		final source = new TableSqlSource(new QualifiedTableName("books"), "t0");
		final del = new DeleteExpression(source);
		del.Where = new BinarySqlExpression(new ColumnSqlExpression(source, "Id", SqlInt), Equal, Expr.constInt(1));
		del.Returning.push(new ColumnSqlExpression(source, "Id", SqlInt));
		del.Returning.push(new ColumnSqlExpression(source, "Title", SqlText));
		return del;
	}

	function testPostgres_Delete_RendersReturning() {
		// The port aliases the target, so what comes back is named through the alias.
		final sql = new SqlTranslator().ToSql(DeleteWithReturning());
		Assert.contains("RETURNING t0.Id, t0.Title", sql);
	}

	function testSqlServer_Delete_RendersOutputBeforeWhere() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testMySql_Delete_Throws() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testSqlite_Delete_Returning_RoundTrips() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
