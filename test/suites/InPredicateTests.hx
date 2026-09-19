package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/**
	`InPredicateTests.cs` — `WHERE x IN (…)` from a membership test on a captured collection. C#'s
	`List<T>` is an `Array` here, which is what has `contains`.
**/
class InPredicateTests extends TestCase {
	function testArrayContains_BuildsInList() {
		final ids = [1, 2, 3];

		final select = Query.select(Book).Where(b -> ids.contains(b.id)).ToExpression();

		final membership = select.whereClause().inValues([1, 2, 3]);
		membership.Value.column("id");
	}

	function testListContains_BuildsInList() {
		final titles = ["A", "B"];

		final select = Query.select(Book).Where(b -> titles.contains(b.title)).ToExpression();

		final membership = select.whereClause().inValues(["A", "B"]);
		membership.Value.column("title");
	}

	function testNotContains_WrapsTheListInNot() {
		final ids = [4, 5];

		final select = Query.select(Book).Where(b -> !ids.contains(b.id)).ToExpression();

		// The ! wraps the IN in a NOT rather than negating the IN itself.
		final negated = select.whereClause().not();
		final membership = negated.Operand.inValues([4, 5]);
		membership.Value.column("id");
	}

	function testEmptyList_MatchesNothing() {
		final ids:Array<Int> = [];

		final select = Query.select(Book).Where(b -> ids.contains(b.id)).ToExpression();

		// Nothing is in an empty list, so the predicate is a membership test with nothing to match.
		final membership = select.whereClause().isIn();
		membership.Value.column("id");
		Assert.empty(membership.Values);
	}

	function testInList_CombinesWithOtherPredicates() {
		final ids = [1, 2];

		final select = Query.select(Book)
			.Where(b -> ids.contains(b.id) && b.publishedYear > 2000)
			.ToExpression();

		final and = select.whereBinary(And);
		and.Left.inValues([1, 2]).Value.column("id");
		and.Right.comparison("publishedYear", GreaterThan, 2000);
	}
}
