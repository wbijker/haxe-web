package suites;

import codequery.DbCase;
import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.simplecase.Entities;

using codequery.testing.SqlAssert;

/** `SimpleCaseTests.cs` — simple `CASE operand WHEN value THEN result` expressions via `DbCase.On(…)`. */
class SimpleCaseTests extends TestCase {
	static function assertCase(e:ISqlExpression, branchCount:Int):CaseSqlExpression {
		final branches = e.caseWhen();
		Assert.count(branchCount, branches.Branches);
		return branches;
	}

	function testSimpleCase_WithElse() {
		final branches = assertCase(
			Query.select(Product).Select(p -> DbCase.On(p.grade).When("A", 1).When("B", 2).Else(0)).ToExpression()
				.subquery().selectionAt(0),
			2);

		// A simple CASE compares one operand against each arm's value, rather than testing a predicate.
		branches.Operand.column("grade");

		branches.Branches[0].When.value("A");
		branches.Branches[0].Then.value(1);
		branches.Branches[1].When.value("B");
		branches.Branches[1].Then.value(2);
		branches.Otherwise.value(0);
	}

	function testSimpleCase_NoElse_UsesEnd() {
		final branches = assertCase(
			Query.select(Product).Select(p -> DbCase.On(p.grade).When("A", 1).End()).ToExpression()
				.subquery().selectionAt(0),
			1);

		branches.Operand.column("grade");
		Assert.isNull(branches.Otherwise);
	}
}
