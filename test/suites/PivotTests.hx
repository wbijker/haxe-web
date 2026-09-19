package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class PivotSale {
	public var region:String = "";
	public var quarter:String = "";
	public var amount:Float = 0;

	public function new() {}
}

class PivotRegion {
	public var region:String = "";
	public var q1:Float = 0;
	public var q2:Float = 0;

	public function new() {}
}

/** `PivotTests.cs`: PIVOT via portable conditional aggregation (works on every dialect). */
class PivotTests extends TestCase {
	static function Pivoted() {
		return Query.select(PivotSale).Pivot(PivotRegion,
			s -> s.quarter,
			s -> s.amount,
			AggregateType.Sum,
			[{key: "Q1", column: "Q1"}, {key: "Q2", column: "Q2"}],
			s -> {region: s.region});
	}

	function testPivot_BuildsOneConditionalAggregatePerColumn() {
		final select = Pivoted().ToExpression();

		select.groupBy().column("region");
		select.selectionOf("region").column("region");

		AssertPivotColumn(select, "Q1", Sum);
		AssertPivotColumn(select, "Q2", Sum);
	}

	function testPivot_CountAggregate() {
		final select = Query.select(PivotSale).Pivot(PivotRegion,
			s -> s.quarter, s -> s.amount, AggregateType.Count,
			[{key: "Q1", column: "Q1"}],
			s -> {region: s.region})
			.ToExpression();

		AssertPivotColumn(select, "Q1", Count);
	}

	/**
		The member is an aggregate over a CASE that keeps only the rows of that pivot value — which is
		what makes the pivot portable: no dialect needs a PIVOT clause to say it.
	**/
	static function AssertPivotColumn(select:SelectExpression, name:String, type:AggregateType) {
		final aggregate = select.selectionOf(name).aggregate(type);

		final branches = aggregate.Argument.caseWhen();
		Assert.count(1, branches.Branches);
		Assert.isNull(branches.Otherwise);
		branches.Branches[0].When.comparison("quarter", Equal, name);
		branches.Branches[0].Then.column("amount");
	}

	function testPivot_IsPortable_AcrossDialects() {
		// Conditional aggregation needs no native PIVOT support, so it renders on every driver — the
		// C# checks PostgreSQL and SQLite; the port has the one dialect.
		Assert.contains("CASE WHEN", new SqlTranslator().ToSql(Pivoted().ToExpression()));
	}
}
