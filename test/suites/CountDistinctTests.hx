package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("orders")
class CountDistinctOrder {
	public var id:Int = 0;
	public var buyerId:Int = 0;
	public var projectId:Int = 0;

	public function new() {}
}

/** `CountDistinctTests.cs` — `COUNT(DISTINCT …)` per group. */
class CountDistinctTests extends TestCase {
	function testItCountsDistinctValuesPerGroup() {
		final select = Query.select(CountDistinctOrder)
			.GroupBy(o -> o.buyerId)
			.SelectAggregation(g -> {buyer: g.key(o -> o.buyerId), projects: g.countDistinct(o -> o.projectId)})
			.ToExpression();

		Assert.equals("orders", select.selectTableName());
		select.groupBy().column("buyerId");
		select.selectionOf("buyer").column("buyerId");

		final count = select.selectionOf("projects").aggregate(Count);
		count.Argument.column("projectId");
		Assert.isTrue(count.Distinct);
		Assert.isNull(count.Filter);
	}

	function testItTakesAFilter() {
		final select = Query.select(CountDistinctOrder)
			.GroupBy(o -> o.buyerId)
			.SelectAggregation(g -> {recent: g.countDistinct(o -> o.projectId).filter(o -> o.id > 10)})
			.ToExpression();

		final count = select.selectionOf("recent").aggregate(Count);
		count.Argument.column("projectId");
		Assert.isTrue(count.Distinct);
		count.Filter.comparison("id", GreaterThan, 10);
	}

	function testItCountsValuesNotRows() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testTheUngroupedFormIsUnchanged() {
		final select = Query.select(CountDistinctOrder)
			.SelectAggregation(a -> {projects: a.countDistinct(o -> o.projectId)})
			.ToExpression();

		final count = select.selectionOf("projects").aggregate(Count);
		count.Argument.column("projectId");
		Assert.isTrue(count.Distinct);
	}
}
