package suites;

import codequery.DbAggregation;
import codequery.Query;
import codequery.SqlDate;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/**
	`AggregateRulesTests.cs` — SQL's rule about aggregates, as three doors. An aggregate takes many
	rows and yields one, so a select holding one may not also hold a column of a single row — unless
	the aggregate is computed per row, which is what a window is.
**/
class AggregateRulesTests extends TestCase {
	static function sql(select:SelectExpression):String {
		return new SqlTranslator().ToSql(select);
	}

	// --- Beside ordinary columns: a window, and nothing else ---------------------------------------

	function testAnAggregateBesideColumnsIsAWindow() {
		final rendered = sql(Query.select(Booking)
			.Select(b -> {id: b.id, ofUnit: DbAggregation.count().over(b.unitId, null)})
			.ToExpression());

		Assert.contains("COUNT(*) OVER (PARTITION BY t0.unitId) AS ofUnit", rendered);
	}

	function testOverNothingIsTheWholeResult() {
		final rendered = sql(Query.select(Booking)
			.Select(b -> {id: b.id, rows: DbAggregation.count().over()})
			.ToExpression());

		Assert.contains("COUNT(*) OVER () AS rows", rendered);
	}

	function testAnAggregateWithoutAWindowIsRefused() {
		final select = Query.select(Booking)
			.Select(b -> {id: b.id, rows: DbAggregation.count()})
			.ToExpression();
		final error = Assert.throwsMessage(() -> sql(select));

		Assert.contains("finished with Over(...)", error);
		Assert.contains("SelectAggregation", error);
		Assert.contains("GroupBy", error);
	}

	// --- Nothing but aggregates --------------------------------------------------------------------

	function testSelectAggregationSelectsOnlyAggregates() {
		final select = Query.select(Booking)
			.SelectAggregation(a -> {rows: a.count(), latest: a.max(b -> b.checkIn)})
			.ToExpression();

		Assert.equals("SELECT COUNT(*) AS rows, MAX(t0.checkIn) AS latest FROM bookings AS t0", sql(select));
	}

	function testItAggregatesWhatTheQueryReturns() {
		final rendered = sql(Query.select(Booking)
			.Where(b -> b.unitId == 10)
			.SelectAggregation(a -> a.count())
			.ToExpression());

		Assert.contains("SELECT COUNT(*) FROM bookings AS t0 WHERE t0.unitId = 10", rendered);
	}

	function testItCarriesFiltersAndDistinct() {
		final cutoff:SqlDate = new Date(2026, 0, 1, 0, 0, 0);

		final rendered = sql(Query.select(Booking)
			.SelectAggregation(a -> {
				recent: a.count().filter(b -> b.checkIn > cutoff),
				units: a.countDistinct(b -> b.unitId),
				takings: a.sumDistinct(b -> b.totalCents),
			})
			.ToExpression());

		Assert.contains("COUNT(*) FILTER (WHERE", rendered);
		Assert.contains("COUNT(DISTINCT t0.unitId)", rendered);
		Assert.contains("SUM(DISTINCT t0.totalCents)", rendered);
	}

	function testThereIsNoGroupBy() {
		final select = Query.select(Booking)
			.SelectAggregation(a -> {rows: a.count()})
			.ToExpression();

		Assert.empty(select.GroupBy);
		Assert.equals("bookings", select.selectTableName());
	}

	// --- One per group -----------------------------------------------------------------------------

	function testAGroupedAggregateKeepsItsKey() {
		final rendered = sql(Query.select(Booking)
			.GroupBy(b -> b.unitId)
			.SelectAggregation(g -> {key: g.key(b -> b.unitId), rows: g.count()})
			.ToExpression());

		Assert.contains("GROUP BY t0.unitId", rendered);
		Assert.contains("COUNT(*) AS rows", rendered);
	}

	// --- One aggregate, asked for directly ---------------------------------------------------------

	function testTheShorthandsAskForOneNumber() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testTheAggregatesComeBack() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}

@tableName("bookings")
class Booking {
	public var id:Int = 0;
	public var unitId:Int = 0;
	public var checkIn:SqlDate;
	public var totalCents:Float = 0;

	public function new() {}
}
