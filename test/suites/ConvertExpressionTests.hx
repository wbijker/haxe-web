package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/**
	`ConvertExpressionTests.cs`. C#'s `Convert.ToX(…)` and `(int)x` are `Sql.castTo(x, SqlType)` and
	`cast(x, Int)` here; the `SqlType` names are the port's own (`Text` for a string, `Timestamp` for
	a date-time, one `Float` for double and single alike).
**/
class ConvertExpressionTests extends TestCase {
	// System.Convert methods

	function testConvert_ToInt32() {
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.title, SqlInt))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlInt, converted.Type);
		Assert.notNull(converted.Value);
		final col = Assert.isType(converted.Value, ColumnSqlExpression);
		Assert.equals("title", col.ColumnName);
	}

	function testConvert_ToInt64() {
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.publishedYear, SqlBigInt))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlBigInt, converted.Type);
		Assert.notNull(converted.Value);
	}

	function testConvert_ToInt16() {
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.publishedYear, SqlSmallInt))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlSmallInt, converted.Type);
		Assert.notNull(converted.Value);
	}

	function testConvert_ToDouble() {
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.publishedYear, SqlFloat))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlFloat, converted.Type);
		Assert.notNull(converted.Value);
	}

	function testConvert_ToSingle() {
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.publishedYear, SqlReal))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlReal, converted.Type);
		Assert.notNull(converted.Value);
	}

	function testConvert_ToDecimal() {
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.publishedYear, SqlDecimal(18, 2)))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlDecimal(18, 2), converted.Type);
		Assert.notNull(converted.Value);
	}

	function testConvert_ToString() {
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.publishedYear, SqlText))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlText, converted.Type);
		Assert.notNull(converted.Value);
	}

	function testConvert_ToBoolean() {
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.publishedYear, SqlBool))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlBool, converted.Type);
		Assert.notNull(converted.Value);
	}

	function testConvert_ToDateTime() {
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.title, SqlTimestamp))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlTimestamp, converted.Type);
		Assert.notNull(converted.Value);
	}

	// Explicit cast expressions

	function testExplicitCast_ToInt() {
		final exp = Query.select(Book)
			.Select(b -> cast(b.authorId, Int))
			.ToExpression();

		// int to int creates a cast function
		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlInt, converted.Type);
		Assert.notNull(converted.Value);
		final col = Assert.isType(converted.Value, ColumnSqlExpression);
		Assert.equals("authorId", col.ColumnName);
	}

	function testExplicitCast_ToLong() {
		// Haxe has no 64-bit integer type to cast to, so the SQL type is named directly.
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.publishedYear, SqlBigInt))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlBigInt, converted.Type);
		Assert.notNull(converted.Value);
	}

	function testExplicitCast_ToDouble() {
		final exp = Query.select(Book)
			.Select(b -> cast(b.publishedYear, Float))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlFloat, converted.Type);
		Assert.notNull(converted.Value);
	}

	function testExplicitCast_ToDecimal() {
		// Haxe has no decimal type to cast to, so the SQL type is named directly.
		final exp = Query.select(Book)
			.Select(b -> Sql.castTo(b.publishedYear, SqlDecimal(18, 2)))
			.ToExpression();

		final converted = Assert.isType(exp.Selection, SqlCastExpression);
		Assert.equals(SqlType.SqlDecimal(18, 2), converted.Type);
		Assert.notNull(converted.Value);
	}

	// Constant type conversions

	function testIntConstant() {
		final exp = Query.select(Book)
			.Where(b -> b.id == 42)
			.ToExpression();

		final binary = Assert.isType(exp.Where, BinarySqlExpression);
		final value = Assert.isType(binary.Right, ConstSqlExpression);
		Assert.isTrue(value.Value.match(SqlConstInt(_)));
	}

	function testBoolConstant() {
		final exp = Query.select(Book)
			.Where(b -> Sql.like(b.title, "%test%") == true)
			.ToExpression();

		final binary = Assert.isType(exp.Where, BinarySqlExpression);
		final value = Assert.isType(binary.Right, ConstSqlExpression);
		Assert.isTrue(value.Value.match(SqlConstBool(_)));
	}

	function testStringConstant() {
		final exp = Query.select(Book)
			.Where(b -> b.title == "Test Book")
			.ToExpression();

		final binary = Assert.isType(exp.Where, BinarySqlExpression);
		final value = Assert.isType(binary.Right, ConstSqlExpression);
		Assert.equals("Test Book", SqlAssert.ValueOfConst(value.Value));
		Assert.isTrue(value.Value.match(SqlConstString(_)));
	}

	function testFloatConstant() {
		final exp = Query.select(Book)
			.Select(b -> 3.14)
			.ToExpression();

		final value = Assert.isType(exp.Selection, ConstSqlExpression);
		Assert.isTrue(value.Value.match(SqlConstFloat(_)));
	}

	function testDoubleConstant() {
		// Haxe has one floating-point type, so a double is the same constant a float is.
		final exp = Query.select(Book)
			.Select(b -> 3.14159)
			.ToExpression();

		final value = Assert.isType(exp.Selection, ConstSqlExpression);
		Assert.isTrue(value.Value.match(SqlConstFloat(_)));
	}

	// SQL type mappings

	function testIntColumn_HasIntType() {
		final exp = Query.select(Book)
			.Select(b -> b.id)
			.ToExpression();

		final col = Assert.isType(exp.Selection, ColumnSqlExpression);
		Assert.equals(SqlType.SqlInt, col.ColumnType);
	}

	function testStringColumn_HasTextType() {
		final exp = Query.select(Book)
			.Select(b -> b.title)
			.ToExpression();

		final col = Assert.isType(exp.Selection, ColumnSqlExpression);
		Assert.equals(SqlType.SqlText, col.ColumnType);
	}

	function testDateTimeColumn_HasDateTimeType() {
		final exp = Query.select(Book)
			.Select(b -> b.publishedDate)
			.ToExpression();

		final col = Assert.isType(exp.Selection, ColumnSqlExpression);
		Assert.equals(SqlType.SqlTimestamp, col.ColumnType);
	}
}
