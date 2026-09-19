package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** `QuantifiedComparisonTests.cs` — `DbFunctions.All/Any/Some` are `Sql.all/any/some`. */
class QuantifiedComparisonTests extends TestCase {
	function testGreaterThanAll_ComparesAgainstEveryRow() {
		final years = Query.select(Book).Where(x -> x.authorId == 1).Select(x -> x.publishedYear);

		final select = Query.select(Book).Where(b -> b.publishedYear > Sql.all(years)).ToExpression();

		final quantified = select.whereClause().quantified(GreaterThan, true);
		quantified.Value.column("publishedYear");
		quantified.Subquery.selectionAt(0).column("publishedYear");
	}

	function testEqualsAny_ComparesAgainstSomeRow() {
		final ids = Query.select(Author).Select(a -> a.id);

		final select = Query.select(Book).Where(b -> b.authorId == Sql.any(ids)).ToExpression();

		final quantified = select.whereClause().quantified(Equal, false);
		quantified.Value.column("authorId");
		Assert.equals("Author", quantified.Subquery.selectTableName());
	}

	function testSome_IsSynonymForAny() {
		final ids = Query.select(Author).Select(a -> a.id);

		final select = Query.select(Book).Where(b -> b.authorId == Sql.some(ids)).ToExpression();

		select.whereClause().quantified(Equal, false);
	}

	function testQuantifierOnLeft_FlipsOperator() {
		final years = Query.select(Book).Select(x -> x.publishedYear);

		// Sql.all(years) < b.publishedYear  ==  b.publishedYear > ALL (years)
		final select = Query.select(Book).Where(b -> Sql.all(years) < b.publishedYear).ToExpression();

		// The quantifier is always the right-hand side, so the operator turns round with it.
		final quantified = select.whereClause().quantified(GreaterThan, true);
		quantified.Value.column("publishedYear");
	}
}
