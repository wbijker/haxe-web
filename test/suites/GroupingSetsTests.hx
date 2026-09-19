package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class GroupingSale {
	public var region:Int = 0;
	public var year:Int = 0;
	public var amount:Float = 0;

	public function new() {}
}

/**
	`GroupingSetsTests.cs` — `GROUP BY ROLLUP / CUBE / GROUPING SETS`.

	C# carries a composite key as one projection term; here a structure key is its columns, one
	term each, which is what `ROLLUP (a, b)` takes, and a grouping set is a list of them.
**/
class GroupingSetsTests extends TestCase {
	function testRollup() {
		final select = Query.select(GroupingSale)
			.GroupByRollup(s -> {region: s.region, year: s.year})
			.SelectAggregation(a -> {region: a.key(s -> s.region), year: a.key(s -> s.year), total: a.sum(s -> s.amount)})
			.ToExpression();

		Assert.equals(GroupingMode.Rollup, select.Grouping);

		// The key is the columns it rolls up — which is what ROLLUP (a, b) takes.
		Assert.equals(2, select.GroupBy.length);
		select.groupBy(0).column("region");
		select.groupBy(1).column("year");

		select.selectionOf("total").aggregate(Sum).Argument.column("amount");
	}

	function testCube() {
		final select = Query.select(GroupingSale)
			.GroupByCube(s -> {region: s.region, year: s.year})
			.SelectAggregation(a -> {region: a.key(s -> s.region), year: a.key(s -> s.year), total: a.sum(s -> s.amount)})
			.ToExpression();

		Assert.equals(GroupingMode.Cube, select.Grouping);

		Assert.equals(2, select.GroupBy.length);
		select.groupBy(0).column("region");
		select.groupBy(1).column("year");
	}

	function testGroupingSets() {
		final select = Query.select(GroupingSale)
			.GroupByGroupingSets(s -> {region: s.region, year: s.year}, s -> {region: s.region}, s -> {})
			.SelectAggregation(a -> {total: a.sum(s -> s.amount)})
			.ToExpression();

		Assert.equals(GroupingMode.GroupingSets, select.Grouping);
		Assert.equals(3, select.GroupingSets.length);

		// Each set is the columns it groups by; the last is the empty one, the grand total.
		final both = select.GroupingSets[0];
		Assert.equals(2, both.length);
		both[0].column("region");
		both[1].column("year");

		final region = select.GroupingSets[1];
		Assert.single(region).column("region");

		Assert.empty(select.GroupingSets[2]);
	}
}
