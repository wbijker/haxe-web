package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using StringTools;
using codequery.testing.SqlAssert;

/** `StringExpressionTests.cs`. */
class StringExpressionTests extends TestCase {
	// LIKE-based operations

	function testContains() {
		final exp = Query.select(Book).Where(b -> b.title.contains("Test")).ToExpression();

		final where = Assert.isType(exp.Where, StringOperationExpression);
		Assert.equals(StringOperationType.Contains, where.OperationType);
		where.Operand.column("title");
		where.Pattern.constant("Test");
	}

	function testStartsWith() {
		final exp = Query.select(Book).Where(b -> b.title.startsWith("The")).ToExpression();

		final where = Assert.isType(exp.Where, StringOperationExpression);
		Assert.equals(StringOperationType.StartsWith, where.OperationType);
		where.Operand.column("title");
	}

	function testEndsWith() {
		final exp = Query.select(Book).Where(b -> b.title.endsWith("Book")).ToExpression();

		final where = Assert.isType(exp.Where, StringOperationExpression);
		Assert.equals(StringOperationType.EndsWith, where.OperationType);
		where.Operand.column("title");
	}

	// SQL function operations

	function testToUpper() {
		final func = Query.select(Book).Select(b -> b.title.toUpperCase()).ToExpression().selectionAt(0).call(SqlFunctions.Upper);
		Assert.single(func.Arguments).column("title");
	}

	function testToLower() {
		final func = Query.select(Book).Select(b -> b.title.toLowerCase()).ToExpression().selectionAt(0).call(SqlFunctions.Lower);
		Assert.single(func.Arguments);
	}

	function testTrim() {
		final func = Query.select(Book).Select(b -> b.title.trim()).ToExpression().selectionAt(0).call(SqlFunctions.Trim);
		Assert.single(func.Arguments);
	}

	function testTrimStart() {
		final func = Query.select(Book).Select(b -> b.title.ltrim()).ToExpression().selectionAt(0).call(SqlFunctions.TrimStart);
		Assert.single(func.Arguments);
	}

	function testTrimEnd() {
		final func = Query.select(Book).Select(b -> b.title.rtrim()).ToExpression().selectionAt(0).call(SqlFunctions.TrimEnd);
		Assert.single(func.Arguments);
	}

	function testSubstring() {
		final func = Query.select(Book).Select(b -> b.title.substr(0, 10)).ToExpression().selectionAt(0).call(SqlFunctions.Substring);
		Assert.count(3, func.Arguments); // operand + startIndex + length
		func.Arguments[0].column("title");
		Assert.isTrue(func.Arguments[1].constant().Value.match(SqlConstInt(_)));
		Assert.isTrue(func.Arguments[2].constant().Value.match(SqlConstInt(_)));
	}

	function testReplace() {
		final func = Query.select(Book).Select(b -> b.title.replace("old", "new")).ToExpression().selectionAt(0).call(SqlFunctions.Replace);
		Assert.count(3, func.Arguments); // operand + oldValue + newValue
		func.Arguments[0].column("title");
	}

	function testIndexOf() {
		final func = Query.select(Book).Select(b -> b.title.indexOf("test")).ToExpression().selectionAt(0).call(SqlFunctions.IndexOf);
		Assert.count(2, func.Arguments); // operand + value
	}

	function testPadLeft() {
		final func = Query.select(Book).Select(b -> b.title.lpad(" ", 20)).ToExpression().selectionAt(0).call(SqlFunctions.PadLeft);
		Assert.count(2, func.Arguments); // operand + totalWidth
	}

	function testPadRight() {
		final func = Query.select(Book).Select(b -> b.title.rpad(" ", 20)).ToExpression().selectionAt(0).call(SqlFunctions.PadRight);
		Assert.count(2, func.Arguments); // operand + totalWidth
	}

	function testLength() {
		final func = Query.select(Book).Select(b -> b.title.length).ToExpression().selectionAt(0).call(SqlFunctions.Length);
		Assert.single(func.Arguments).column("title");
	}
}
