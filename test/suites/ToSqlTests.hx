package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.SqlDate;
import codequery.sqldrivers.NormalizedSqlTranslator;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("product")
class ToSqlProduct {
	public var id:Int = 0;
	public var name:String = "";
	public var created:SqlDate;
	public var categoryId:Int = 0;

	public function new() {}
}

@tableName("category")
class ToSqlCategory {
	public var id:Int = 0;
	public var title:String = "";

	public function new() {}
}

/**
	`ToSqlTests.cs` — a statement rendered to be read. By default the SQL that goes to the database,
	values pulled out into parameters; normalized, the values written back in so it stands alone.

	C# renders through `db.Config()` or a driver; here a statement is handed to a translator, and
	`NormalizedSqlTranslator` is `normalize: true`.
**/
class ToSqlTests extends TestCase {
	static function products():DbTable<ToSqlProduct> {
		return Query.table(ToSqlProduct);
	}

	static function categories():DbTable<ToSqlCategory> {
		return Query.table(ToSqlCategory);
	}

	static function sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	static function normalized(statement:ISqlStatement):String {
		return new NormalizedSqlTranslator().ToSql(statement);
	}

	function testByDefault_TheValuesAreParameters() {
		final minId = 42;
		final rendered = sql(products().From().Where(p -> p.id > minId).ToExpression());

		Assert.contains("t0.id > $1", rendered);
		Assert.doesNotContain("42", rendered);
	}

	function testNormalized_TheValuesAreWrittenIn() {
		final minId = 42;
		final rendered = normalized(products().From().Where(p -> p.id > minId).ToExpression());

		Assert.contains("t0.id > 42", rendered);
		Assert.doesNotContain("$1", rendered);
	}

	function testADriver_RendersTheTreeWithoutAConfigurationAroundIt() {
		final minId = 42;
		final expression = products().From().Where(p -> p.id > minId).ToExpression();

		Assert.contains("> 42", normalized(expression));
		Assert.contains("> $1", sql(expression));
	}

	function testTheSameTree_RendersInWhicheverDialectIsAsked() {
		final expression = products().From().Where(p -> p.name == "x").ToExpression();

		// One tree, rendered in the one dialect this port has; the SQL Server half of the C# test
		// (`FROM [product]`) is MssqlSqlDriver's, which is not here.
		Assert.contains("FROM product", normalized(expression));
	}

	function testNormalized_AStringIsQuotedByTheDialect() {
		final name = "O'Brien";
		final rendered = normalized(products().From().Where(p -> p.name == name).ToExpression());

		// Doubled, not left to end the literal early.
		Assert.contains("'O''Brien'", rendered);
	}

	function testNormalized_ADateIsALiteral() {
		final cutoff:SqlDate = new Date(2026, 0, 31, 12, 0, 0);
		final rendered = normalized(products().From().Where(p -> p.created < cutoff).ToExpression());

		Assert.contains("'2026-01-31 12:00:00'", rendered);
	}

	function testAJoinedQuery() {
		final rendered = normalized(products().From()
			.InnerJoin(categories(), (p, c) -> p.categoryId == c.id)
			.Where((p, c) -> c.title == "tools")
			.ToExpression());

		Assert.contains("INNER JOIN", rendered);
		Assert.contains("'tools'", rendered);
	}

	function testAGroupedQuery() {
		final rendered = normalized(products().From()
			.GroupBy(p -> p.categoryId)
			.Having(g -> g.count() > 2)
			.ToExpression());

		Assert.contains("GROUP BY", rendered);
		Assert.contains("HAVING", rendered);
	}

	function testAnUpdate() {
		final id = 7;
		final expression = products().Update().Set(p -> p.name, "renamed").Where(p -> p.id == id).ToExpression();

		Assert.startsWith("UPDATE", sql(expression));
		Assert.contains("t0.id = $1", sql(expression));
		Assert.contains("t0.id = 7", normalized(expression));
	}

	function testADelete() {
		final id = 7;
		final expression = products().Delete().Where(p -> p.id == id).ToExpression();

		Assert.startsWith("DELETE", sql(expression));
		Assert.contains("$1", sql(expression));
		Assert.contains("= 7", normalized(expression));
	}

	function testAValueWrittenIntoTheLambda_IsAConstantEitherWay() {
		final expression = products().From().Where(p -> p.id > 10).ToExpression();

		Assert.contains("> 10", sql(expression));
		Assert.contains("> 10", normalized(expression));
		Assert.doesNotContain("$", sql(expression));
	}

	function testAConfiguration_RunsTheInterceptor_AndADriverDoesNot() {
		Assert.skip("Profiler/Logger/Interceptor: not ported");
	}

	function testWithNoDialectToRenderIn_ItSaysSo() {
		Assert.skip("SelectExpression.ToSql(driver): a statement is rendered by a translator here, there is no driver argument to be null");
	}
}
