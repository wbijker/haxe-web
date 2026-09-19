package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** `UnionQueryTests.cs`. */
class UnionQueryTests extends TestCase {
	function testUnionAll_KeepsTheMembersInOrder() {
		final recent = Query.select(Book).Where(b -> b.publishedYear > 2000).Select(b -> {id: b.id, title: b.title});
		final classic = Query.select(Book).Where(b -> b.publishedYear <= 2000).Select(b -> {id: b.id, title: b.title});

		final select = recent.UnionAll(classic).ToExpression();

		// The statement it was called on is the first member; the one passed in follows it.
		select.whereClause().comparison("publishedYear", GreaterThan, 2000);

		final member = select.union();
		Assert.equals(SetOperationType.UnionAll, member.Type);
		member.Query.whereClause().comparison("publishedYear", LessThanOrEqual, 2000);
	}

	function testUnion_DoesNotKeepDuplicates() {
		final one = Query.select(Book).Select(b -> {id: b.id});
		final two = Query.select(Book).Select(b -> {id: b.id});

		final select = one.Union(two).ToExpression();

		final member = select.union();
		Assert.equals(SetOperationType.Union, member.Type);
	}

	function testUnionAll_OrderByBelongsToTheCombinedResult() {
		final recent = Query.select(Book).Where(b -> b.publishedYear > 2000).Select(b -> {id: b.id});
		final classic = Query.select(Book).Where(b -> b.publishedYear <= 2000).Select(b -> {id: b.id});

		final select = recent.UnionAll(classic).OrderAsc(x -> x.id).ToExpression();

		// The ordering becomes a statement around the combined rows, so it orders those rather than either
		// member's own — neither member is ordered.
		select.orderBy().Expression.column("id");
		Assert.isTrue(select.orderBy().Ascending);

		final combined = select.subquery();
		Assert.empty(combined.OrderBy);
		Assert.empty(combined.union().Query.OrderBy);
	}

	function testUnionAll_FetchesRowsFromAllMembers() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
