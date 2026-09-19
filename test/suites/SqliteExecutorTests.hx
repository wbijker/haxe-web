package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/**
	`SqliteExecutorTests.cs`.

	Most of it runs statements against an in-memory SQLite database, which the eval target has no
	way to reach; two tests only build a query and look at it, and those are here for real.
**/
class SqliteExecutorTests extends TestCase {
	static final Database = "needs a database: eval has none (PHP runtime only)";
	static final Dialect = "SqliteSqlDriver: no SQLite dialect in this port";

	function testSelectAll() {
		Assert.skip(Database);
	}

	function testSelectWithWhere() {
		Assert.skip(Database);
	}

	function testSelectDynamic() {
		Assert.skip(Database);
	}

	function testSelectWithExpression() {
		final select = Query.select(Book)
			.Where(b -> b.publishedYear > 2020)
			.ToExpression();

		select.whereClause().comparison("publishedYear", GreaterThan, 2020);
	}

	function testInsertAndSelect() {
		Assert.skip(Database);
	}

	function testUpdateAndVerify() {
		Assert.skip(Database);
	}

	function testDeleteAndVerify() {
		Assert.skip(Database);
	}

	function testExecuteScalar() {
		Assert.skip(Database);
	}

	function testAQueryCarriesEveryClauseItWasGiven() {
		// C#'s `b.Title.Contains("Book")` is a LIKE with the wildcards written out here.
		final select = Query.select(Book)
			.Where(b -> Sql.like(b.title, "%Book%"))
			.OrderByDesc(b -> b.publishedYear)
			.ToExpression();

		Assert.equals("Book", select.selectTableName());
		final like = select.whereClause().call("LIKE");
		like.Arguments[0].column("title");
		like.Arguments[1].value("%Book%");
		select.orderBy().Expression.column("publishedYear");
		Assert.isFalse(select.orderBy().Ascending);
	}

	function testSqliteSqlDriver_DateFunctions() {
		Assert.skip(Dialect);
	}

	function testSqliteSqlDriver_StringFunctions() {
		Assert.skip(Dialect);
	}

	function testSqliteSqlDriver_BooleanAsInteger() {
		Assert.skip(Dialect);
	}
}
