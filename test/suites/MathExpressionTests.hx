package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** `MathExpressionTests.cs`. */
class MathExpressionTests extends TestCase {
	// Arithmetic operators

	function testAdd() {
		final exp = Query.select(Book).Select(b -> b.publishedYear + 1).ToExpression();

		final binary = exp.selectionAt(0).binary(Add);
		binary.Left.column("publishedYear");
		final value = binary.Right.constant();
		Assert.isTrue(value.Value.match(SqlConstInt(1)));
	}

	function testSubtract() {
		final exp = Query.select(Book).Select(b -> b.publishedYear - 10).ToExpression();

		final binary = exp.selectionAt(0).binary(Subtract);
		binary.Left.column("publishedYear");
	}

	function testMultiply() {
		final exp = Query.select(Book).Select(b -> b.publishedYear * 2).ToExpression();
		exp.selectionAt(0).binary(Multiply);
	}

	function testDivide() {
		final exp = Query.select(Book).Select(b -> b.publishedYear / 100).ToExpression();
		exp.selectionAt(0).binary(Divide);
	}

	function testModulo() {
		final exp = Query.select(Book).Select(b -> b.publishedYear % 100).ToExpression();
		exp.selectionAt(0).binary(Modulo);
	}

	// Column to column operations

	function testAddColumns() {
		final exp = Query.select(Book).Select(b -> b.publishedYear + b.authorId).ToExpression();

		final binary = exp.selectionAt(0).binary(Add);
		binary.Left.column("publishedYear");
		binary.Right.column("authorId");
	}

	function testSubtractColumns() {
		final exp = Query.select(Book).Select(b -> b.publishedYear - b.authorId).ToExpression();
		exp.selectionAt(0).binary(Subtract);
	}

	// Chained operations

	function testChainedOperations() {
		final exp = Query.select(Book).Select(b -> (b.publishedYear + 1) * 2).ToExpression();

		final outer = exp.selectionAt(0).binary(Multiply);
		outer.Left.binary(Add);
	}

	// Comparison operators

	function testEqual() {
		Query.select(Book).Where(b -> b.publishedYear == 2020).ToExpression().whereBinary(Equal);
	}

	function testNotEqual() {
		Query.select(Book).Where(b -> b.publishedYear != 2020).ToExpression().whereBinary(NotEqual);
	}

	function testLessThan() {
		Query.select(Book).Where(b -> b.publishedYear < 2020).ToExpression().whereBinary(LessThan);
	}

	function testLessThanOrEqual() {
		Query.select(Book).Where(b -> b.publishedYear <= 2020).ToExpression().whereBinary(LessThanOrEqual);
	}

	function testGreaterThan() {
		Query.select(Book).Where(b -> b.publishedYear > 2020).ToExpression().whereBinary(GreaterThan);
	}

	function testGreaterThanOrEqual() {
		Query.select(Book).Where(b -> b.publishedYear >= 2020).ToExpression().whereBinary(GreaterThanOrEqual);
	}

	// Logical operators

	function testAnd() {
		final exp = Query.select(Book).Where(b -> b.publishedYear > 2000 && b.publishedYear < 2020).ToExpression();

		final binary = exp.whereBinary(And);
		binary.Left.binary(GreaterThan);
		binary.Right.binary(LessThan);
	}

	function testOr() {
		final exp = Query.select(Book).Where(b -> b.publishedYear < 2000 || b.publishedYear > 2020).ToExpression();
		exp.whereBinary(Or);
	}
}
