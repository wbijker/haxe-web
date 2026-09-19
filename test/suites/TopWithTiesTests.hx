package suites;

import codequery.Query;
import codequery.queries.ISelectQuery;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class TopSale {
	public var id:Int = 0;
	public var amount:Float = 0;

	public function new() {}
}

/** `TopWithTiesTests.cs` — `WITH TIES` / `PERCENT` across dialects; this port has the one. */
class TopWithTiesTests extends TestCase {
	static function topByAmount():ISelectQuery<TopSale> {
		return Query.select(TopSale).OrderByDesc(s -> s.amount).Limit(10);
	}

	function testWithTiesAndPercent_AreClausesOfTheStatement() {
		final plain = topByAmount().ToExpression();
		Assert.equals(10, plain.Limit);
		Assert.isFalse(plain.WithTies);
		Assert.isFalse(plain.Percent);

		Assert.isTrue(topByAmount().WithTies().ToExpression().WithTies);
		Assert.isTrue(topByAmount().Percent().ToExpression().Percent);
	}

	function testWithTies_SqlServer_UsesTop() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testPercent_SqlServer_UsesTopPercent() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testWithTies_Postgres_UsesFetchFirstWithTies() {
		final sql = new SqlTranslator().ToSql(topByAmount().WithTies().ToExpression());

		// The standard's form rather than LIMIT, which cannot say it.
		Assert.contains("10 ROWS WITH TIES", sql);
		Assert.doesNotContain("LIMIT", sql);
	}

	function testPercent_Postgres_Throws() {
		Assert.skip("PostgresSqlDriver: refusing PERCENT is the PostgreSQL dialect's; this port renders the standard's FETCH … PERCENT");
	}

	function testWithTies_Sqlite_Throws() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testPlainLimit_Unaffected() {
		Assert.contains("LIMIT 10", new SqlTranslator().ToSql(topByAmount().ToExpression()));
	}
}
