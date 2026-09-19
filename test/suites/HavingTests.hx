package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** `HavingTests.cs` — `HAVING` on an aggregation. */
class HavingTests extends TestCase {
	function testHaving_CountAggregate_ComparesTheCount() {
		final select = Query.select(Book)
			.GroupBy(b -> b.authorId)
			.Having(g -> g.count() > 5)
			.SelectAggregation(g -> {authorId: g.key(b -> b.authorId)})
			.ToExpression();

		select.groupBy().column("authorId");

		final having = select.havingBinary();
		Assert.equals(SqlBinaryOperator.GreaterThan, having.Operator);
		Assert.isNull(having.Left.aggregate(Count).Argument);
		having.Right.constant(5);
	}

	function testHaving_SumAggregate_ComparesTheSum() {
		final select = Query.select(Book)
			.GroupBy(b -> b.authorId)
			.Having(g -> g.sum(b -> b.publishedYear) > 100)
			.SelectAggregation(g -> {authorId: g.key(b -> b.authorId)})
			.ToExpression();

		final having = select.havingBinary(GreaterThan);
		having.Left.aggregate(Sum).Argument.column("publishedYear");
		having.Right.constant(100);
	}

	function testHaving_OnGroupingKey_ResolvesToGroupedColumn_NotLiteralKey() {
		final select = Query.select(Book)
			.GroupBy(b -> b.authorId)
			.Having(g -> g.key(b -> b.authorId) > 10)
			.SelectAggregation(g -> {authorId: g.key(b -> b.authorId)})
			.ToExpression();

		select.havingClause().comparison("authorId", GreaterThan, 10);
	}

	function testHaving_CalledTwice_CombinesWithAnd() {
		final select = Query.select(Book)
			.GroupBy(b -> b.authorId)
			.Having(g -> g.count() > 5)
			.Having(g -> g.sum(b -> b.publishedYear) > 100)
			.SelectAggregation(g -> {authorId: g.key(b -> b.authorId)})
			.ToExpression();

		final and = select.havingBinary();
		Assert.equals(SqlBinaryOperator.And, and.Operator);

		final count = and.Left.binary(GreaterThan);
		count.Left.aggregate(Count);
		count.Right.constant(5);

		final sum = and.Right.binary(GreaterThan);
		sum.Left.aggregate(Sum).Argument.column("publishedYear");
		sum.Right.constant(100);
	}

	function testHaving_StaysWithItsGrouping_WhenTheResultIsOrdered() {
		// Ordering a grouped result orders the rows the grouping produced, so it becomes a statement of its
		// own around the grouped one rather than another clause on it. HAVING stays where its aggregates are.
		final ordered = Query.select(Book)
			.GroupBy(b -> b.authorId)
			.Having(g -> g.count() > 5)
			.SelectAggregation(g -> {authorId: g.key(b -> b.authorId)})
			.OrderBy(x -> x.authorId)
			.ToExpression();

		Assert.single(ordered.OrderBy);
		Assert.isNull(ordered.Having);
		Assert.empty(ordered.GroupBy);

		final grouped = ordered.subquery();
		Assert.single(grouped.GroupBy);
		grouped.havingBinary(GreaterThan).Left.aggregate(Count);
	}

	function testHaving_OverJoinedTwoTableGroup_ResolvesKeyAndAggregate() {
		final select = Query.select(Book)
			.InnerJoin(Query.select(Author), (b, a) -> a.id == b.authorId)
			.GroupBy((book, author) -> author.authorGroupId)
			.Having(g -> g.count() > 2)
			.Having(g -> g.key((book, author) -> author.authorGroupId) > 0)
			.SelectAggregation(g -> {groupId: g.key((book, author) -> author.authorGroupId)})
			.ToExpression();

		final and = select.havingBinary(And);

		final count = and.Left.binary(GreaterThan);
		count.Left.aggregate(Count);
		count.Right.constant(2);

		// The key resolves to the joined table's column, not to the one this statement selects from.
		final key = and.Right.binary(GreaterThan);
		final column = key.Left.column("authorGroupId");
		Assert.notEqual(select.Source.Alias, column.Source.Alias);
		key.Right.constant(0);
	}
}
