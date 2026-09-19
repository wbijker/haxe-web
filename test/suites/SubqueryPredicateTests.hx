package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** `SubqueryPredicateTests.cs` — `DbFunctions.In` is `Sql.inQuery`, `DbFunctions.Exists` is `Sql.exists`. */
class SubqueryPredicateTests extends TestCase {
	function testIn_Subquery_TestsMembershipOfItsRows() {
		final authorsInUk = Query.select(Author).Where(a -> a.name != "Anon").Select(a -> a.id);

		final select = Query.select(Book).Where(b -> Sql.inQuery(b.authorId, authorsInUk)).ToExpression();

		final membership = select.whereClause().isIn();
		membership.Value.column("authorId");

		final subquery = select.whereClause().inSubquery();
		Assert.equals("Author", subquery.selectTableName());
		subquery.selectionAt(0).column("id");
	}

	function testExists_Subquery_IsNotNegated() {
		final anyAuthor = Query.select(Author).Where(a -> a.id == 1);

		final select = Query.select(Book).Where(b -> Sql.exists(anyAuthor)).ToExpression();

		final exists = select.whereClause().exists();
		Assert.equals("Author", exists.Subquery.selectTableName());
		exists.Subquery.whereClause().comparison("id", Equal, 1);
	}

	function testNotExists_Subquery_IsNegated() {
		final anyAuthor = Query.select(Author).Where(a -> a.id == 1);

		final select = Query.select(Book).Where(b -> Sql.notExists(anyAuthor)).ToExpression();

		Assert.equals("Author", select.whereClause().exists(true).Subquery.selectTableName());
	}

	function testIn_Subquery_CombinesWithPredicates() {
		final ids = Query.select(Author).Select(a -> a.id);

		final select = Query.select(Book)
			.Where(b -> b.publishedYear > 2000 && Sql.inQuery(b.authorId, ids))
			.ToExpression();

		final and = select.whereBinary(And);
		and.Left.comparison("publishedYear", GreaterThan, 2000);
		Assert.equals("Author", and.Right.inSubquery().selectTableName());
	}
}
