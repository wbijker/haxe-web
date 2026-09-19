package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class CteRow {
	public var id:Int = 0;
	public var amount:Float = 0;

	public function new() {}
}

/**
	`WithCteTests.cs` — `AsCte`. A window function inside a plain `Select` is written here as an
	aggregate projection: `a.rowNumber().overRows(…)` beside the keys it selects.
**/
class WithCteTests extends TestCase {
	function testAsCte_MarksTheStatementAndTheOnesItReadsFrom() {
		final baseQ = Query.select(CteRow)
			.Where(r -> r.amount > 0)
			.Select(r -> {id: r.id, amount: r.amount})
			.AsCte();

		final ranked = baseQ
			.SelectAggregation(a -> {
				id: a.key(r -> r.id),
				amount: a.key(r -> r.amount),
				rn: a.rowNumber().overRows(w -> w.PartitionBy(r -> r.id).OrderByDesc(r -> r.amount))
			})
			.AsCte();

		final select = ranked.Where(r -> r.rn == 1).ToExpression();

		// The outer statement is not itself a CTE; it reads from one.
		Assert.isFalse(select.IsCte);
		select.whereClause().comparison("rn", Equal, 1);

		final second = select.subquery();
		Assert.isTrue(second.IsCte);
		second.selectionOf("rn").windowFunction(RowNumber);

		// …which in turn reads from the first, so the WITH clause has to name them in that order.
		final first = second.subquery();
		Assert.isTrue(first.IsCte);
		first.whereClause().comparison("amount", GreaterThan, 0);
	}

	function testAsCte_TakesAnExplicitName() {
		final totals = Query.select(CteRow)
			.Select(r -> {id: r.id})
			.AsCte("totals");

		final select = totals.Where(r -> r.id > 0).ToExpression();

		final cte = select.subquery();
		Assert.isTrue(cte.IsCte);
		Assert.equals("totals", cte.CteName);
	}

	function testNoCte_IsNotMarked() {
		final select = Query.select(CteRow).Where(r -> r.amount > 0).ToExpression();

		Assert.isFalse(select.IsCte);
		Assert.isNull(select.CteName);
	}

	// ---- how the WITH clause comes out -----------------------------------------------------------------

	function testAsCte_HoistsMarkedQueriesIntoWithClauseInDependencyOrder() {
		final baseQ = Query.select(CteRow)
			.Where(r -> r.amount > 0)
			.Select(r -> {id: r.id, amount: r.amount})
			.AsCte();

		final ranked = baseQ
			.SelectAggregation(a -> {
				id: a.key(r -> r.id),
				amount: a.key(r -> r.amount),
				rn: a.rowNumber().overRows(w -> w.PartitionBy(r -> r.id).OrderByDesc(r -> r.amount))
			})
			.AsCte();

		final query = ranked.Where(r -> r.rn == 1);

		final sql = new SqlTranslator().ToSql(query.ToExpression());

		Assert.startsWith("WITH cte1 AS (", sql);
		Assert.contains("cte2 AS (", sql);
		Assert.contains("FROM cte1 AS", sql); // cte2 (ranked) references cte1 (base)
		Assert.contains("ROW_NUMBER() OVER", sql); // window lives inside cte2
		Assert.contains("FROM cte2 AS", sql); // the outer query references cte2
		Assert.contains(".rn = 1", sql);
	}

	function testAsCte_UsesExplicitNameWhenGiven() {
		final totals = Query.select(CteRow)
			.Select(r -> {id: r.id})
			.AsCte("totals");

		final query = totals.Where(r -> r.id > 0);

		final sql = new SqlTranslator().ToSql(query.ToExpression());

		Assert.startsWith("WITH totals AS (", sql);
		Assert.contains("FROM totals AS", sql);
	}

	function testNoCte_RendersWithoutWithClause() {
		final sql = new SqlTranslator().ToSql(Query.select(CteRow).Where(r -> r.amount > 0).ToExpression());

		Assert.doesNotContain("WITH", sql);
	}
}
