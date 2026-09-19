package suites;

import codequery.DbAggregation;
import codequery.Query;
import codequery.Sql;
import codequery.SqlDate;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/** `AggregateFilterTests.cs` — aggregate `FILTER (WHERE …)`, combinable with `OVER (…)` windows. */
class AggregateFilterTests extends TestCase {
	/** The C# `AssertAggregate(e, type, column)`: the aggregate, and the column it is over. */
	static function aggregateOf(e:ISqlExpression, type:AggregateType, column:String):AggregateSqlExpression {
		final aggregate = e.aggregate(type);
		aggregate.Argument.column(column);
		return aggregate;
	}

	function testFilter_OnPlainAggregate_CarriesThePredicate() {
		final select = Query.select(Transaction)
			.SelectAggregation(a -> a.sum(t -> t.amount).filter(t -> t.amount > 0))
			.ToExpression();

		final sum = aggregateOf(select.selectionAt(0), Sum, "amount");
		sum.Filter.comparison("amount", GreaterThan, 0);
		Assert.isFalse(sum.Windowed);
	}

	function testFilter_WithWindow_KeepsBoth() {
		// SELECT SUM(amount) FILTER (WHERE amount > 0) OVER (ORDER BY order_date) AS running_credits
		final select = Query.select(Transaction)
			.Select(t -> {
				orderDate: t.orderDate,
				amount: t.amount,
				runningCredits: DbAggregation.sum(t.amount).filter(t.amount > 0).over(null, t.orderDate)
			})
			.ToExpression();

		final sum = aggregateOf(select.selectionOf("runningCredits"), Sum, "amount");
		sum.Filter.comparison("amount", GreaterThan, 0);
		Assert.isTrue(sum.Windowed);
		Assert.empty(sum.PartitionBy);
		Assert.single(sum.OrderBy).Expression.column("orderDate");
		Assert.isTrue(sum.OrderBy[0].Ascending);
	}

	function testWindowedAggregate_WithPartition() {
		final select = Query.select(Transaction)
			.Select(t -> DbAggregation.sum(t.amount).over(t.accountId, t.orderDate))
			.ToExpression();

		final sum = aggregateOf(select.selectionAt(0), Sum, "amount");
		Assert.isTrue(sum.Windowed);
		Assert.single(sum.PartitionBy).column("accountId");
		Assert.single(sum.OrderBy).Expression.column("orderDate");
	}

	function testWindowedAggregate_NullOrderBy_PartitionOnly() {
		// MAX(order_date) OVER (PARTITION BY account_id) — the whole partition, not a running frame.
		final select = Query.select(Transaction)
			.Select(t -> {accountId: t.accountId, maxDate: DbAggregation.max(t.orderDate).over(t.accountId, null)})
			.ToExpression();

		final max = aggregateOf(select.selectionOf("maxDate"), Max, "orderDate");
		Assert.isTrue(max.Windowed);
		Assert.single(max.PartitionBy).column("accountId");
		Assert.empty(max.OrderBy);
	}

	function testWindowedAggregate_BothNull_IsAWindowOverEverything() {
		final select = Query.select(Transaction)
			.Select(t -> DbAggregation.sum(t.amount).over(null, null))
			.ToExpression();

		final sum = aggregateOf(select.selectionAt(0), Sum, "amount");
		Assert.isTrue(sum.Windowed);
		Assert.empty(sum.PartitionBy);
		Assert.empty(sum.OrderBy);
	}

	function testFilteredAggregate_InGroupByProjection_MonthlyPivot() {
		final select = Query.select(Transaction)
			.GroupBy(a -> a.accountId)
			.SelectAggregation(a -> {
				accountId: a.key(g -> g.accountId),
				jan: a.sum(g -> g.amount).filter(g -> Sql.datePart("month", g.orderDate) == 1),
				feb: a.sum(g -> g.amount).filter(g -> Sql.datePart("month", g.orderDate) == 2),
			})
			.ToExpression();

		select.groupBy().column("accountId");

		assertMonthFilteredSum(select.selectionOf("jan"), 1);
		assertMonthFilteredSum(select.selectionOf("feb"), 2);
	}

	static function assertMonthFilteredSum(expression:ISqlExpression, month:Int) {
		final sum = aggregateOf(expression, Sum, "amount");
		final filter = sum.Filter.binary(Equal);
		// EXTRACT(month FROM order_date): the one argument is `month FROM order_date`.
		final extract = filter.Left.call("EXTRACT");
		Assert.count(1, extract.Arguments);
		extract.Arguments[0].call("FROM").Arguments[1].column("orderDate");
		filter.Right.value(month);
	}

	function testFilteredAggregate_InMultiSourceGroupByProjection() {
		// Aggregate over a two-table group (Transaction joined to Account) with a filter.
		final select = Query.select(Transaction)
			.InnerJoin(Query.table(Account, "Account"), (t, acc) -> t.accountId == acc.id)
			.GroupBy((t, acc) -> acc.name)
			.SelectAggregation(a -> {
				name: a.key((t, acc) -> acc.name),
				credits: a.sum((t, acc) -> t.amount).filter((t, acc) -> t.amount > 0),
				creditCount: a.count().filter((t, acc) -> t.amount > 0),
			})
			.ToExpression();

		final credits = aggregateOf(select.selectionOf("credits"), Sum, "amount");
		credits.Filter.comparison("amount", GreaterThan, 0);

		// COUNT(*) — a count of the rows that pass the filter, not of a column.
		final creditCount = select.selectionOf("creditCount").aggregate(Count);
		Assert.isNull(creditCount.Argument);
		creditCount.Filter.comparison("amount", GreaterThan, 0);
	}

	function testCountFilter_InGroupByProjection() {
		final select = Query.select(Transaction)
			.GroupBy(a -> a.accountId)
			.SelectAggregation(a -> {key: a.key(g -> g.accountId), credits: a.count().filter(g -> g.amount > 0)})
			.ToExpression();

		final count = select.selectionOf("credits").aggregate(Count);
		Assert.isNull(count.Argument);
		count.Filter.comparison("amount", GreaterThan, 0);
	}

	function testCountStar_WithFilter() {
		final select = Query.select(Transaction)
			.SelectAggregation(a -> a.count().filter(t -> t.amount > 0))
			.ToExpression();

		final count = select.selectionAt(0).aggregate(Count);
		Assert.isNull(count.Argument);
		count.Filter.comparison("amount", GreaterThan, 0);
	}

	// ---- what a dialect without FILTER makes of it ------------------------------------------------

	function testFilter_SqlServer_RewritesToConditionalAggregation() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testCountStar_Filter_SqlServer_UsesCaseThen1() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}
}

class Transaction {
	public var orderDate:SqlDate;
	public var amount:Float = 0;
	public var accountId:Int = 0;

	public function new() {}
}

class Account {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}
