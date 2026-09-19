package suites;

import codequery.DbAggregation;
import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/** `AggregateDistinctTests.cs` — `COUNT(DISTINCT x)`, `SUM(DISTINCT x)`, combinable with FILTER. */
class AggregateDistinctTests extends TestCase {
	function testCountDistinct_MarksTheAggregate() {
		final select = Query.select(Sale)
			.SelectAggregation(a -> a.countDistinct(s -> s.customerId))
			.ToExpression();

		final count = select.selectionAt(0).aggregate(Count);
		count.Argument.column("customerId");
		Assert.isTrue(count.Distinct);
	}

	function testSumDistinct_MarksTheAggregate() {
		final select = Query.select(Sale)
			.SelectAggregation(a -> a.sumDistinct(s -> s.amount))
			.ToExpression();

		final sum = select.selectionAt(0).aggregate(Sum);
		sum.Argument.column("amount");
		Assert.isTrue(sum.Distinct);
	}

	function testCountDistinct_CombinesWithFilter() {
		final select = Query.select(Sale)
			.SelectAggregation(a -> a.countDistinct(s -> s.customerId).filter(s -> s.amount > 0))
			.ToExpression();

		final count = select.selectionAt(0).aggregate(Count);
		count.Argument.column("customerId");
		Assert.isTrue(count.Distinct);
		count.Filter.comparison("amount", GreaterThan, 0);
	}

	function testAggDistinct_WrapsTheProjectedColumn() {
		final select = Query.select(Sale)
			.Select(s -> {customerId: DbAggregation.distinct(s.customerId), amount: s.amount})
			.ToExpression();

		// DbAggregation.distinct is the DISTINCT keyword in front of the projection, so it wraps the
		// first member rather than becoming an aggregate of its own.
		select.selectionOf("customerId").expression(DistinctSqlExpression).Value.column("customerId");
		select.selectionOf("amount").column("amount");
	}

	function testAggDistinct_SaysWhatTheQueryLevelDistinctSays() {
		final keyword = Query.select(Sale)
			.Select(s -> {customerId: DbAggregation.distinct(s.customerId)})
			.ToExpression();

		final queryStep = Query.select(Sale)
			.Select(s -> {customerId: s.customerId})
			.Distinct()
			.ToExpression();

		// Same statement, two spellings: the keyword form marks the projected member, while the
		// query step marks the statement — and the statement is the projection's own, since
		// DISTINCT names no columns and needs none of its own.
		keyword.selectionOf("customerId").expression(DistinctSqlExpression).Value.column("customerId");

		Assert.isTrue(queryStep.IsDistinct);
		queryStep.selectionOf("customerId").column("customerId");
	}
}

class Sale {
	public var customerId:Int = 0;
	public var amount:Float = 0;

	public function new() {}
}
