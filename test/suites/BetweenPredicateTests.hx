package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** `BetweenPredicateTests.cs` — `DbFunctions.Between` is `Sql.between`. */
class BetweenPredicateTests extends TestCase {
	function testBetween_BuildsBetweenPredicate() {
		final select = Query.select(Book)
			.Where(b -> Sql.between(b.publishedYear, 1990, 2000))
			.ToExpression();

		final between = select.whereClause().between();
		between.Value.column("publishedYear");
		between.Lower.constant(1990);
		between.Upper.constant(2000);
	}

	function testNotBetween_NegatesThePredicate() {
		final select = Query.select(Book)
			.Where(b -> Sql.notBetween(b.publishedYear, 1990, 2000))
			.ToExpression();

		final between = select.whereClause().between(true);
		between.Value.column("publishedYear");
		between.Lower.constant(1990);
		between.Upper.constant(2000);
	}

	function testBetween_WithColumnBounds() {
		final select = Query.select(Book)
			.Where(b -> Sql.between(b.publishedYear, b.authorId, b.id))
			.ToExpression();

		final between = select.whereClause().between();
		between.Value.column("publishedYear");
		between.Lower.column("authorId");
		between.Upper.column("id");
	}

	function testBetween_CombinesWithPredicates() {
		final select = Query.select(Book)
			.Where(b -> b.authorId == 1 && Sql.between(b.publishedYear, 1990, 2000))
			.ToExpression();

		final and = select.whereBinary(And);
		and.Left.comparison("authorId", Equal, 1);
		and.Right.between();
	}
}
