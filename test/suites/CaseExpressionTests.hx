package suites;

import codequery.DbCase;
import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.caseexpression.Entities;

using codequery.testing.SqlAssert;

/** `CaseExpressionTests.cs` — the explicit `DbCase.When(…).Else(…)` builder, alongside the ternary CASE. */
class CaseExpressionTests extends TestCase {
	static function assertCase(e:ISqlExpression, branchCount:Int):CaseSqlExpression {
		final branches = e.caseWhen();
		Assert.count(branchCount, branches.Branches);
		return branches;
	}

	function testCase_MultipleWhen_WithElse() {
		final select = Query.select(Sale)
			.Select(g -> DbCase
				.When(g.id < 10, g.totalAmount)
				.When(g.id < 20, g.totalAmount * 2)
				.Else(g.totalAmount * 3))
			.ToExpression();

		final branches = assertCase(select.subquery().selectionAt(0), 2);

		// A searched CASE tests a predicate per arm rather than comparing one operand.
		Assert.isNull(branches.Operand);

		branches.Branches[0].When.comparison("id", LessThan, 10);
		branches.Branches[0].Then.column("totalAmount");

		branches.Branches[1].When.comparison("id", LessThan, 20);
		branches.Branches[1].Then.comparison("totalAmount", Multiply, 2);

		branches.Otherwise.comparison("totalAmount", Multiply, 3);
	}

	function testCase_SingleWhen_WithElse() {
		final select = Query.select(Sale).Select(g -> DbCase.When(g.id < 10, "small").Else("big")).ToExpression();

		final branches = assertCase(select.subquery().selectionAt(0), 1);
		branches.Branches[0].When.comparison("id", LessThan, 10);
		branches.Branches[0].Then.value("small");
		branches.Otherwise.value("big");
	}

	function testCase_End_OmitsElse() {
		final select = Query.select(Sale).Select(g -> DbCase.When(g.id < 10, "small").End()).ToExpression();

		final branches = assertCase(select.subquery().selectionAt(0), 1);
		Assert.isNull(branches.Otherwise);
	}

	/** The C# also selects the group's key as `Id`; the aggregate set here has no key to read, so only the sum is asserted. */
	function testCase_InAggregateSum() {
		final select = Query.select(Sale)
			.GroupBy(s -> s.id)
			.SelectAggregation(a -> {
				sales: a.sum(g -> DbCase
					.When(g.id < 10, g.totalAmount)
					.When(g.id < 20, g.totalAmount * 2)
					.Else(g.totalAmount * 3))
			})
			.ToExpression();

		final sum = select.subquery().selectionOf("sales").aggregate(Sum);
		final branches = assertCase(sum.Argument, 2);
		branches.Otherwise.comparison("totalAmount", Multiply, 3);
	}

	function testTernary_IsTheSameCase() {
		final select = Query.select(Sale).Select(g -> g.id < 10 ? "small" : "big").ToExpression();

		final branches = assertCase(select.subquery().selectionAt(0), 1);
		branches.Branches[0].When.comparison("id", LessThan, 10);
		branches.Branches[0].Then.value("small");
		branches.Otherwise.value("big");
	}
}
