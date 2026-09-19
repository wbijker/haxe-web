package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("orders")
class DistinctOrder {
	public var id:Int = 0;
	public var buyerId:Int = 0;
	public var projectId:Int = 0;

	public function new() {}
}

/**
	`DistinctGroupByTests.cs` — `Select(…).Distinct().GroupBy(…)`: the distinct pairs, counted by
	the first. The deduping half goes in a derived table and the grouping reads from it.
**/
class DistinctGroupByTests extends TestCase {
	function testTheDedupeHappensBeforeTheGrouping() {
		final select = Query.select(DistinctOrder)
			.Select(o -> {buyerId: o.buyerId, projectId: o.projectId})
			.Distinct()
			.GroupBy(x -> x.buyerId)
			.SelectAggregation(g -> {buyer: g.key(x -> x.buyerId), projects: g.count()})
			.ToExpression();

		// The grouping statement does not dedupe — that is the one that was wrong.
		Assert.isFalse(select.IsDistinct);
		select.groupBy().column("buyerId");
		select.selectionOf("buyer").column("buyerId");
		Assert.isNull(select.selectionOf("projects").aggregate(Count).Argument);

		// It reads from something that does — the dedupe wraps the projection it dedupes.
		final deduped = select.subquery();
		Assert.isTrue(deduped.IsDistinct);
		Assert.equals(["buyerId", "projectId"], deduped.subquery().memberNames());
		Assert.equals("orders", deduped.selectTableName());
	}

	function testWithoutDistinctNothingIsNested() {
		final select = Query.select(DistinctOrder)
			.GroupBy(o -> o.buyerId)
			.SelectAggregation(g -> {buyer: g.key(o -> o.buyerId), orders: g.count()})
			.ToExpression();

		// The table itself, not a derived one.
		Assert.equals("orders", select.tableSource().Table.Name);
		select.groupBy().column("buyerId");
		select.selectionOf("buyer").column("buyerId");
		Assert.isNull(select.selectionOf("orders").aggregate(Count).Argument);
	}

	function testDistinctOnNestsToo() {
		final select = Query.select(DistinctOrder)
			.Distinct(o -> o.projectId)
			.OrderBy(o -> o.projectId)
			.Select(o -> {buyerId: o.buyerId, projectId: o.projectId})
			.GroupBy(x -> x.buyerId)
			.SelectAggregation(g -> {buyer: g.key(x -> x.buyerId), projects: g.count()})
			.ToExpression();

		Assert.empty(select.DistinctOn);
		select.groupBy().column("buyerId");

		final deduped = select.subquery();
		Assert.single(deduped.DistinctOn).column("projectId");
		Assert.equals("orders", deduped.selectTableName());
	}

	function testTheCountIsOfPairsNotRows() {
		final select = Query.select(DistinctOrder)
			.Select(o -> {buyerId: o.buyerId, projectId: o.projectId})
			.Distinct()
			.GroupBy(x -> x.buyerId)
			.SelectAggregation(g -> {buyer: g.key(x -> x.buyerId), projects: g.count()})
			.ToExpression();

		// One count, and it is over the deduped rows — which are pairs, because the pair is what was kept.
		select.selectionOf("projects").aggregate(Count);

		final pairs = select.subquery().subquery().memberNames();
		Assert.equals(["buyerId", "projectId"], pairs);
	}
}
