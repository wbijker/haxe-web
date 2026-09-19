package suites;

import codequery.Query;
import codequery.SqlDate;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("readings")
class DistinctReading {
	@columnName("device_id") public var deviceId:String = "";
	@columnName("reading_at") public var readingAt:SqlDate;
	@columnName("value") public var value:Float = 0;

	public function new() {}
}

/**
	`DistinctOnTests.cs` — `DistinctOn`: one row per distinct key, the first in the query's own
	ordering. This port renders the clause as PostgreSQL has it; the row-number fallback the other
	dialects are given is theirs.
**/
class DistinctOnTests extends TestCase {
	static final Fallback = "SqliteSqlDriver: the DISTINCT ON row-number fallback is another dialect's rendering";

	/** The latest reading per device — what the feature is for. */
	static function latestPerDevice():SelectExpression {
		return Query.select(DistinctReading)
			.Distinct(r -> r.deviceId)
			.OrderBy(r -> r.deviceId)
			.OrderByDesc(r -> r.readingAt)
			.Select(r -> {deviceId: r.deviceId, readingAt: r.readingAt, value: r.value})
			.ToExpression();
	}

	function testTheKeyIsAClauseOfTheStatement() {
		final select = latestPerDevice();

		Assert.single(select.DistinctOn).column("device_id");
		Assert.isFalse(select.IsDistinct);

		Assert.equals(2, select.OrderBy.length);
		select.orderBy(0).Expression.column("device_id");
		Assert.isTrue(select.orderBy(0).Ascending);
		select.orderBy(1).Expression.column("reading_at");
		Assert.isFalse(select.orderBy(1).Ascending);
	}

	function testPostgres_SaysItDirectly() {
		Assert.equals(
			"SELECT DISTINCT ON (t0.device_id) t0.device_id AS deviceId, t0.reading_at AS readingAt, t0.value AS value "
			+ "FROM readings AS t0 ORDER BY t0.device_id ASC, t0.reading_at DESC",
			new SqlTranslator().ToSql(latestPerDevice()));
	}

	function testTheOthers_NumberTheRowsAndKeepTheFirst() {
		Assert.skip(Fallback);
	}

	function testEveryDialectWithoutTheClause_WritesTheFallback() {
		Assert.skip(Fallback);
	}

	function testAFilterIsAppliedBeforeTheNumbering() {
		Assert.skip(Fallback);
	}

	function testSeveralKeys() {
		final select = Query.select(DistinctReading)
			.Distinct(r -> r.deviceId)
			.Distinct(r -> r.value)
			.OrderByDesc(r -> r.readingAt)
			.Select(r -> {deviceId: r.deviceId, value: r.value})
			.ToExpression();

		Assert.equals(2, select.DistinctOn.length);
		select.DistinctOn[0].column("device_id");
		select.DistinctOn[1].column("value");
	}

	// ---- one or the other ------------------------------------------------------------------------------

	function testAQueryIsOneOrTheOther() {
		final onThenAll = Assert.throwsMessage(() -> Query.select(DistinctReading).Distinct(r -> r.deviceId).Distinct());
		final allThenOn = Assert.throwsMessage(() -> Query.select(DistinctReading).Distinct().Distinct(r -> r.deviceId));

		Assert.contains("DISTINCT or DISTINCT ON, not both", onThenAll);
		Assert.equals(onThenAll, allThenOn);
	}

	function testDedupingWhatADistinctOnReturned_IsAQueryOverIt() {
		final perDevice = Query.select(DistinctReading)
			.Distinct(r -> r.deviceId)
			.OrderBy(r -> r.deviceId)
			.OrderByDesc(r -> r.readingAt)
			.Select(r -> {value: r.value})
			.AsCte("per_device");

		final select = perDevice.Distinct().ToExpression();

		Assert.isTrue(select.IsDistinct);
		Assert.empty(select.DistinctOn);

		final inner = select.subquery();
		Assert.isFalse(inner.IsDistinct);
		Assert.single(inner.DistinctOn).column("device_id");
	}

	// ---- what the fallback cannot do -------------------------------------------------------------------

	function testAJoinedQuery_IsRefusedWhereThereIsNoDistinctOn() {
		final query = Query.select(DistinctReading)
			.InnerJoin(Query.select(DistinctReading), (a, b) -> a.deviceId == b.deviceId)
			.Distinct((a, b) -> a.deviceId)
			.Select((a, b) -> {deviceId: a.deviceId})
			.ToExpression();

		// SQLite's refusal is the fallback's; the dialect here has the clause, so the same query is fine.
		Assert.contains("DISTINCT ON", new SqlTranslator().ToSql(query));
	}

	function testWithoutAProjection_TheFallbackAsksForOne() {
		Assert.skip(Fallback);
	}
}
