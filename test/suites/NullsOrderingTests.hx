package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class NullsRow {
	public var id:Int = 0;
	public var score:Null<Int>;

	public function new() {}
}

/** `NullsOrderingTests.cs` — `ORDER BY … NULLS FIRST/LAST`. */
class NullsOrderingTests extends TestCase {
	function testTheNullsOrdering_IsPartOfTheOrderByTerm() {
		final last = Query.select(NullsRow).OrderBy(r -> r.score, NullsOrdering.Last).ToExpression();
		Assert.equals(NullsOrdering.Last, last.orderBy().Nulls);
		Assert.isTrue(last.orderBy().Ascending);
		last.orderBy().Expression.column("score");

		final first = Query.select(NullsRow).OrderBy(r -> r.score, NullsOrdering.First).ToExpression();
		Assert.equals(NullsOrdering.First, first.orderBy().Nulls);

		// Not saying where nulls go is its own answer: the dialect's default, whatever that is.
		final unsaid = Query.select(NullsRow).OrderByDesc(r -> r.score).ToExpression();
		Assert.equals(NullsOrdering.Default, unsaid.orderBy().Nulls);
		Assert.isFalse(unsaid.orderBy().Ascending);
	}

	function testPostgres_RendersNullsClause() {
		final sql = new SqlTranslator().ToSql(
			Query.select(NullsRow).OrderBy(r -> r.score, NullsOrdering.Last).ToExpression());
		Assert.contains("ORDER BY t0.score ASC NULLS LAST", sql);
	}

	function testSqlServer_EmulatesWithCase() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testDefault_RendersNoNullsClause() {
		final sql = new SqlTranslator().ToSql(Query.select(NullsRow).OrderByDesc(r -> r.score).ToExpression());
		Assert.contains("ORDER BY t0.score DESC", sql);
		Assert.doesNotContain("NULLS", sql);
	}
}
