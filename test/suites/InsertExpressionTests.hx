package suites;

import codequery.InsertStrategy;
import codequery.QualifiedTableName;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`InsertExpressionTests.cs`.

	The C# asserts each dialect's own spelling — quoted identifiers, `@p0` placeholders — and the
	pretty-printed layout. The port renders one dialect on one line: bare identifiers, `$1`
	placeholders, a space where the layout broke a line. The statements are the same.
**/
class InsertExpressionTests extends TestCase {
	final driver = new SqlTranslator();

	static function CreateTable(name:String):TableSqlSource {
		return new TableSqlSource(new QualifiedTableName(name), "t0");
	}

	static function CreateColumn(name:String, ?source:ISqlSource, ?type:SqlType):ColumnSqlExpression {
		return new ColumnSqlExpression(source != null ? source : new TableSqlSource(new QualifiedTableName("_"), "_"),
			name, type != null ? type : SqlText);
	}

	static function Strategy(mode:ValueMode):InsertStrategy {
		final strategy = new InsertStrategy();
		strategy.ValueMode = mode;
		return strategy;
	}

	// ============ Basic Insert Tests ============

	function testPostgresSimpleInsert() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Strategy = Strategy(Inline);
		expr.Columns.push(CreateColumn("Title"));
		expr.Columns.push(CreateColumn("AuthorId"));
		expr.Values.push([Expr.constString("C# Programming"), Expr.constInt(1)]);

		final sql = driver.ToSql(expr);

		Assert.equals("INSERT INTO Book (Title, AuthorId) VALUES ('C# Programming', 1)", sql);
	}

	function testPostgresInsertMultipleRows() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Strategy = Strategy(Inline);
		expr.Columns.push(CreateColumn("Title"));
		expr.Columns.push(CreateColumn("AuthorId"));
		expr.Values.push([Expr.constString("Book 1"), Expr.constInt(1)]);
		expr.Values.push([Expr.constString("Book 2"), Expr.constInt(2)]);

		final sql = driver.ToSql(expr);

		Assert.equals("INSERT INTO Book (Title, AuthorId) VALUES ('Book 1', 1), ('Book 2', 2)", sql);
	}

	function testPostgresInsertWithReturning() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Columns.push(CreateColumn("Title"));
		expr.Returning.push(CreateColumn("Id", table));
		expr.Values.push([Expr.constString("New Book")]);

		final sql = driver.ToSql(expr);

		Assert.contains("RETURNING t0.Id", sql);
	}

	function testSqliteSimpleInsert() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Strategy = Strategy(Inline);
		expr.Columns.push(CreateColumn("Title"));
		expr.Values.push([Expr.constString("SQLite Book")]);

		final sql = driver.ToSql(expr);

		Assert.equals("INSERT INTO Book (Title) VALUES ('SQLite Book')", sql);
	}

	function testSqliteInsertWithReturning() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Columns.push(CreateColumn("Title"));
		expr.Returning.push(CreateColumn("Id", table));
		expr.Values.push([Expr.constString("New Book")]);

		final sql = driver.ToSql(expr);

		Assert.contains("RETURNING t0.Id", sql);
	}

	// ============ InsertStrategy ValueMode Tests ============

	function testPostgresStrategy_Parameterized_UsesParameterPlaceholders() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Strategy = Strategy(Parameterized);
		expr.Columns.push(CreateColumn("Title"));
		expr.Columns.push(CreateColumn("AuthorId", SqlInt));
		expr.Values.push([Expr.constString("Book 1"), Expr.constInt(1)]);
		expr.Values.push([Expr.constString("Book 2"), Expr.constInt(2)]);

		final sql = driver.ToSql(expr);

		Assert.equals("INSERT INTO Book (Title, AuthorId) VALUES ($1, $2), ($3, $4)", sql);
	}

	function testPostgresStrategy_EscapedInline_InlinesValues() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Strategy = Strategy(Inline);
		expr.Columns.push(CreateColumn("Title"));
		expr.Columns.push(CreateColumn("AuthorId", SqlInt));
		expr.Values.push([Expr.constString("Book's Title"), Expr.constInt(1)]);

		final sql = driver.ToSql(expr);

		Assert.equals("INSERT INTO Book (Title, AuthorId) VALUES ('Book''s Title', 1)", sql);
	}

	function testSqliteStrategy_Parameterized_UsesParameterPlaceholders() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Strategy = Strategy(Parameterized);
		expr.Columns.push(CreateColumn("Title"));
		expr.Values.push([Expr.constString("Book 1")]);
		expr.Values.push([Expr.constString("Book 2")]);

		final sql = driver.ToSql(expr);

		Assert.equals("INSERT INTO Book (Title) VALUES ($1), ($2)", sql);
	}

	function testSqliteStrategy_EscapedInline_InlinesValues() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Strategy = Strategy(Inline);
		expr.Columns.push(CreateColumn("Title"));
		expr.Values.push([Expr.constString("Book's Title")]);

		final sql = driver.ToSql(expr);

		Assert.equals("INSERT INTO Book (Title) VALUES ('Book''s Title')", sql);
	}

	function testPostgresStrategy_Parameterized_WithReturning() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Strategy = Strategy(Parameterized);
		expr.Columns.push(CreateColumn("Title"));
		expr.Returning.push(CreateColumn("Id", table));
		expr.Values.push([Expr.constString("New Book")]);

		final sql = driver.ToSql(expr);

		Assert.contains("VALUES ($1)", sql);
		Assert.contains("RETURNING t0.Id", sql);
	}

	function testSqliteStrategy_Parameterized_WithReturning() {
		final table = CreateTable("Book");
		final expr = new InsertExpression(table);
		expr.Strategy = Strategy(Parameterized);
		expr.Columns.push(CreateColumn("Title"));
		expr.Returning.push(CreateColumn("Id", table));
		expr.Values.push([Expr.constString("New Book")]);

		final sql = driver.ToSql(expr);

		Assert.contains("VALUES ($1)", sql);
		Assert.contains("RETURNING t0.Id", sql);
	}
}
