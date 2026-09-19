package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `OrderedSetAggregateTests.cs` — ordered-set aggregates rendered as `agg(…) WITHIN GROUP (ORDER BY …)`. */
class OrderedSetAggregateTests extends TestCase {
	function testPercentileCont_And_Median() {
		Assert.contains("percentile_cont(0.9) WITHIN GROUP (ORDER BY t0.amount)",
			new SqlTranslator().ToSql(Query.select(OrderedSetRow).Select(r -> Sql.percentileCont(0.9, r.amount)).ToExpression()));
		Assert.contains("percentile_cont(0.5) WITHIN GROUP (ORDER BY t0.amount)",
			new SqlTranslator().ToSql(Query.select(OrderedSetRow).Select(r -> Sql.median(r.amount)).ToExpression()));
	}

	function testPercentileDisc() {
		Assert.contains("percentile_disc(0.5) WITHIN GROUP (ORDER BY t0.amount)",
			new SqlTranslator().ToSql(Query.select(OrderedSetRow).Select(r -> Sql.percentileDisc(0.5, r.amount)).ToExpression()));
	}

	function testMode() {
		Assert.contains("mode() WITHIN GROUP (ORDER BY t0.amount)",
			new SqlTranslator().ToSql(Query.select(OrderedSetRow).Select(r -> Sql.mode(r.amount)).ToExpression()));
	}
}

class OrderedSetRow {
	public var id:Int = 0;
	public var amount:Float = 0;

	public function new() {}
}
