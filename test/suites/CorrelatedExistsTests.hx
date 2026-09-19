package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.correlatedexists.Entities;

using codequery.testing.SqlAssert;

/**
	`CorrelatedExistsTests.cs` — `DbQuery.Exists` is `Sql.exists` here: a correlated EXISTS written
	as a condition, so it can be OR-ed with another one.
**/
class CorrelatedExistsTests extends TestCase {
	static function sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	function testItCorrelatesToTheOuterRow() {
		final select = Query.select(Project)
			.Where(p -> Sql.exists(Query.select(Watch).Where(w -> w.projectId == p.id)))
			.Select(p -> {id: p.id})
			.ToExpression();

		final exists = select.whereClause().exists();
		Assert.equals("watches", exists.Subquery.selectTableName());

		final correlation = exists.Subquery.whereClause().binary(Equal);
		correlation.Left.column("projectId");
		correlation.Right.column("id");

		// The correlation lands on the outer row's column, not on the subquery's own source.
		Assert.contains("FROM projects AS t0 WHERE EXISTS (SELECT * FROM watches AS t1 WHERE t1.projectId = t0.id)", sql(select));
	}

	function testTwoOfThemOr() {
		final me = 42;

		final select = Query.select(Project)
			.Where(p -> Sql.exists(Query.select(Watch).Where(w -> w.projectId == p.id && w.userId == me))
				|| Sql.exists(Query.select(Member).Where(m -> m.projectId == p.id && m.userId == me)))
			.Select(p -> {id: p.id})
			.ToExpression();

		final or = select.whereBinary(Or);

		Assert.equals("watches", or.Left.exists().Subquery.selectTableName());
		Assert.equals("members", or.Right.exists().Subquery.selectTableName());
	}

	function testEachOneIsItsOwnSource() {
		final select = Query.select(Project)
			.Where(p -> Sql.exists(Query.select(Watch).Where(w -> w.projectId == p.id))
				|| Sql.exists(Query.select(Watch).Where(w -> w.projectId == p.id && w.userId == 1)))
			.Select(p -> {id: p.id})
			.ToExpression();

		final or = select.whereBinary(Or);

		final first = or.Left.exists().Subquery;
		final second = or.Right.exists().Subquery;

		Assert.equals("watches", first.selectTableName());
		Assert.equals("watches", second.selectTableName());

		// Each gets an alias of its own, apart from each other and from the outer statement.
		final rendered = sql(select);
		Assert.contains("EXISTS (SELECT * FROM watches AS t1 WHERE t1.projectId = t0.id)", rendered);
		Assert.contains("EXISTS (SELECT * FROM watches AS t2 WHERE t2.projectId = t0.id AND t2.userId = 1)", rendered);
	}

	function testNotExistsNegates() {
		final select = Query.select(Project)
			.Where(p -> Sql.notExists(Query.select(Watch).Where(w -> w.projectId == p.id)))
			.Select(p -> {id: p.id})
			.ToExpression();

		Assert.equals("watches", select.whereClause().exists(true).Subquery.selectTableName());
	}

	function testItReturnsEitherReason() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testOutsideALambdaItSays() {
		Assert.skip("Sql.exists outside a lambda: Sql is an extern that is read while compiling and never runs, "
			+ "so there is no false to answer with");
	}
}
