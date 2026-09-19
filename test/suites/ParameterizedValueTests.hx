package suites;

import codequery.QualifiedTableName;
import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.parameterizedvalue.Entities;

using codequery.testing.SqlAssert;

/**
	`ParameterizedValueTests.cs` — a value that came from a variable travels as a bound parameter; a
	literal written into the query stays part of the query. C#'s `Render` is `ToSql` here, which
	numbers its placeholders; rendering to read is `ToSql` with `InlineValues`.
**/
class ParameterizedValueTests extends TestCase {
	function testAVariable_IsBound_WithItsValue() {
		final minimumAge = 18;
		final translator = new SqlTranslator();
		final sql = translator.ToSql(Query.select(Person).Where(p -> p.age > minimumAge).ToExpression());

		Assert.endsWith("WHERE t0.age > $1", sql);
		final parameter = Assert.single(translator.Parameters);
		Assert.equals(SqlConstValue.SqlConstInt(18), parameter);
	}

	/** A literal is part of what the query says, so it stays in the statement. */
	function testALiteral_StaysInTheStatement() {
		final translator = new SqlTranslator();
		final sql = translator.ToSql(Query.select(Person).Where(p -> p.age > 18).ToExpression());

		Assert.contains("t0.age > 18", sql);
		Assert.empty(translator.Parameters);
	}

	/** The same query rendered to read: nothing there can bind anything, so the value is written in — escaped. */
	function testRenderedToRead_TheValueIsWrittenIn() {
		final name = "O'Brien";
		final translator = new SqlTranslator();
		translator.InlineValues = true;
		final sql = translator.ToSql(Query.select(Person).Where(p -> p.name == name).ToExpression());

		Assert.contains("t0.name = 'O''Brien'", sql);
		Assert.doesNotContain("$", sql);
	}

	/** Null is not bound: SQL compares to it with IS NULL, and `= $1` would never match. */
	function testANullVariable_StaysNull() {
		final missing:String = null;
		final translator = new SqlTranslator();
		final sql = translator.ToSql(Query.select(Person).Where(p -> p.name == missing).ToExpression());

		Assert.contains("IS NULL", sql);
		Assert.empty(translator.Parameters);
	}

	function testEveryValueOfAnInsert_IsBound() {
		final insert = new InsertExpression(new TableSqlSource(new QualifiedTableName("people"), "t0"));
		insert.Columns.push(new ColumnSqlExpression(insert.Target, "name", SqlText));
		insert.Values.push([Expr.constString("Ann")]);

		final translator = new SqlTranslator();
		final sql = translator.ToSql(insert);

		Assert.contains("VALUES ($1)", sql);
		Assert.equals(SqlConstValue.SqlConstString("Ann"), Assert.single(translator.Parameters));
	}

	/** Inline says write the values into the statement, and that is what it does. */
	function testAnInsertAskedToInline_BindsNothing() {
		final insert = new InsertExpression(new TableSqlSource(new QualifiedTableName("people"), "t0"));
		insert.Strategy.ValueMode = Inline;
		insert.Columns.push(new ColumnSqlExpression(insert.Target, "name", SqlText));
		insert.Values.push([Expr.constString("Ann")]);

		final translator = new SqlTranslator();
		final sql = translator.ToSql(insert);

		Assert.contains("VALUES ('Ann')", sql);
		Assert.empty(translator.Parameters);
	}

	function testABoundValue_RoundTrips_AndCannotBreakOutOfTheStatement() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
