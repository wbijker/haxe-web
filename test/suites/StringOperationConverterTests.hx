package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using StringTools;
using codequery.testing.SqlAssert;

/**
	`StringOperationConverterTests.cs`. C# converts a projection lambda directly; here a lambda is
	converted where it is written, so each goes through `Select` and is read back off the selection.
**/
class StringOperationConverterTests extends TestCase {
	function testContains_ConvertsToStringOperation() {
		final result = Query.select(Book).Select(b -> b.title.contains("C#")).ToExpression().selectionAt(0);

		final expr = Assert.isType(result, StringOperationExpression);
		Assert.equals(StringOperationType.Contains, expr.OperationType);
		expr.Operand.column("title");
		expr.Pattern.constant("C#");
	}

	function testStartsWith_ConvertsToStringOperation() {
		final result = Query.select(Book).Select(b -> b.title.startsWith("The")).ToExpression().selectionAt(0);

		final expr = Assert.isType(result, StringOperationExpression);
		Assert.equals(StringOperationType.StartsWith, expr.OperationType);
		expr.Operand.column("title");
		expr.Pattern.constant("The");
	}

	function testEndsWith_ConvertsToStringOperation() {
		final result = Query.select(Book).Select(b -> b.title.endsWith("Guide")).ToExpression().selectionAt(0);

		final expr = Assert.isType(result, StringOperationExpression);
		Assert.equals(StringOperationType.EndsWith, expr.OperationType);
		expr.Operand.column("title");
		expr.Pattern.constant("Guide");
	}

	function testToUpper_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.toUpperCase()).ToExpression().selectionAt(0).call(SqlFunctions.Upper);
		Assert.single(expr.Arguments).column("title");
	}

	function testToLower_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.toLowerCase()).ToExpression().selectionAt(0).call(SqlFunctions.Lower);
		Assert.single(expr.Arguments).column("title");
	}

	function testTrim_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.trim()).ToExpression().selectionAt(0).call(SqlFunctions.Trim);
		Assert.single(expr.Arguments).column("title");
	}

	function testTrimStart_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.ltrim()).ToExpression().selectionAt(0).call(SqlFunctions.TrimStart);
		Assert.single(expr.Arguments).column("title");
	}

	function testTrimEnd_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.rtrim()).ToExpression().selectionAt(0).call(SqlFunctions.TrimEnd);
		Assert.single(expr.Arguments).column("title");
	}

	function testSubstring_WithStartIndex_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.substr(5)).ToExpression().selectionAt(0).call(SqlFunctions.Substring);
		Assert.count(2, expr.Arguments);
		expr.Arguments[0].column("title");
		expr.Arguments[1].constant(5);
	}

	function testSubstring_WithStartIndexAndLength_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.substr(5, 10)).ToExpression().selectionAt(0).call(SqlFunctions.Substring);
		Assert.count(3, expr.Arguments);
		expr.Arguments[0].column("title");
		expr.Arguments[1].constant(5);
		expr.Arguments[2].constant(10);
	}

	function testReplace_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.replace("old", "new")).ToExpression().selectionAt(0).call(SqlFunctions.Replace);
		Assert.count(3, expr.Arguments);
		expr.Arguments[0].column("title");
		expr.Arguments[1].constant("old");
		expr.Arguments[2].constant("new");
	}

	function testIndexOf_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.indexOf("C#")).ToExpression().selectionAt(0).call(SqlFunctions.IndexOf);
		Assert.count(2, expr.Arguments);
		expr.Arguments[0].column("title");
		expr.Arguments[1].constant("C#");
	}

	function testPadLeft_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.lpad(" ", 20)).ToExpression().selectionAt(0).call(SqlFunctions.PadLeft);
		Assert.count(2, expr.Arguments);
		expr.Arguments[0].column("title");
		expr.Arguments[1].constant(20);
	}

	function testPadRight_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.rpad(" ", 20)).ToExpression().selectionAt(0).call(SqlFunctions.PadRight);
		Assert.count(2, expr.Arguments);
		expr.Arguments[0].column("title");
		expr.Arguments[1].constant(20);
	}

	function testLength_ConvertsToSqlFunction() {
		final expr = Query.select(Book).Select(b -> b.title.length).ToExpression().selectionAt(0).call(SqlFunctions.Length);
		Assert.single(expr.Arguments).column("title");
	}
}
