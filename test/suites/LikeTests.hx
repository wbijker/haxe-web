package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.like.Entities;

using codequery.testing.SqlAssert;

/**
	`LikeTests.cs` — `LIKE`, its `ESCAPE` clause, and the case-ignoring `ILIKE`. The C# reads the WHERE
	off PostgreSQL's rendering; the port renders one dialect, whose spelling is asserted here.
**/
class LikeTests extends TestCase {
	/** The rendered WHERE clause, as the C# `Where` helper cuts it out. */
	static function where(statement:ISqlStatement):String {
		final sql = new SqlTranslator().ToSql(statement);
		return sql.substr(sql.indexOf("WHERE ") + 6);
	}

	function testLike() {
		Assert.equals("t0.name LIKE '%bolt%'",
			where(Query.select(Part).Where(p -> Sql.like(p.name, "%bolt%")).Select(p -> {id: p.id}).ToExpression()));
	}

	function testLikeWithAnEscape() {
		Assert.equals("t0.name LIKE '100\\%%' ESCAPE '\\'",
			where(Query.select(Part).Where(p -> Sql.like(p.name, "100\\%%", "\\")).Select(p -> {id: p.id}).ToExpression()));
	}

	function testILike() {
		Assert.equals("t0.name ILIKE '%bolt%'",
			where(Query.select(Part).Where(p -> Sql.ilike(p.name, "%bolt%")).Select(p -> {id: p.id}).ToExpression()));
	}

	function testILikeWithAnEscape() {
		Assert.equals("t0.name ILIKE '100\\%%' ESCAPE '\\'",
			where(Query.select(Part).Where(p -> Sql.ilike(p.name, "100\\%%", "\\")).Select(p -> {id: p.id}).ToExpression()));
	}

	function testILikeIsRefusedWhereItDoesNotExist() {
		Assert.skip("MssqlSqlDriver/SqliteSqlDriver: no SQL Server or SQLite dialect; the one dialect here has ILIKE");
	}

	/** The ESCAPE clause is standard, so every dialect writes it — and so does the one here. */
	function testEveryDialectWritesTheEscapeClause() {
		Assert.contains("ESCAPE",
			where(Query.select(Part).Where(p -> Sql.like(p.name, "100\\%%", "\\")).Select(p -> {id: p.id}).ToExpression()));
	}
}
