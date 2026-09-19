package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.lateralcorrelation.Entities;

using codequery.testing.SqlAssert;

/**
	`LateralCorrelationTests.cs`.

	The C# asserts a correlation's aliases on the built expression. Here a column names its source by
	position, and the alias is settled when the statement renders — so the aliases are read off the
	rendered SQL, which is where they exist.
**/
class LateralCorrelationTests extends TestCase {
	static function sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	// ---- the correlation ---------------------------------------------------------------------------

	function testACorrelatedBody_ReadsTheOuterRow() {
		final select = Query.select(Incident)
			.LeftJoinLateral(f -> Query.select(Telemetry)
				.Where(t -> t.tripNumber == f.identification && t.timestamp <= f.raisedAt)
				.Limit(1))
			.Select((i, a) -> {raisedAt: i.raisedAt})
			.ToExpression();

		final statement = select;
		final body = statement.joinOfType(LeftLateral).Source.asQuery();
		final and = body.whereBinary(And);

		final byTrip = and.Left.binary(Equal);
		byTrip.Left.column("tripNumber");
		byTrip.Right.column("identification");

		final asOf = and.Right.binary(LessThanOrEqual);
		asOf.Left.column("timestamp");
		asOf.Right.column("raisedAt");

		// Both halves name the body's own source on the left and the outer statement's on the right.
		final rendered = sql(select);
		Assert.contains("FROM incidents AS t0 LEFT JOIN LATERAL (SELECT * FROM trip_telemetry AS t2 "
			+ "WHERE t2.tripNumber = t0.identification AND t2.timestamp <= t0.raisedAt LIMIT 1) AS t1 ON TRUE", rendered);
	}

	function testTheThreeSourceOverload_ReadsTheOuterRow() {
		final select = Query.select(Incident)
			.InnerJoin(Query.select(Depot), (i, d) -> i.identification == d.code)
			.LeftJoinLateral((i, d) -> Query.select(Telemetry)
				.Where(t -> t.tripNumber == d.code)
				.Limit(1))
			.Select((i, d, a) -> {raisedAt: i.raisedAt})
			.ToExpression();

		final statement = select;
		statement.joinOfType(Inner, 0);
		final body = statement.joinOfType(LeftLateral, 0).Source.asQuery();

		final correlation = body.whereClause().binary(Equal);
		correlation.Left.column("tripNumber");
		correlation.Right.column("code");

		// The depot is the first join (t1); the body names it, not the statement's own source.
		final rendered = sql(select);
		Assert.contains("INNER JOIN depots AS t1 ON", rendered);
		Assert.contains("LEFT JOIN LATERAL (SELECT * FROM trip_telemetry AS t3 WHERE t3.tripNumber = t1.code LIMIT 1) AS t2 ON TRUE", rendered);
	}

	function testInnerJoinLateral_ReadsTheOuterRow() {
		final select = Query.select(Incident)
			.InnerJoinLateral(f -> Query.select(Telemetry)
				.Where(t -> t.tripNumber == f.identification)
				.Limit(1))
			.Select((i, a) -> {raisedAt: i.raisedAt})
			.ToExpression();

		final body = select.joinOfType(CrossLateral).Source.asQuery();

		final correlation = body.whereClause().binary(Equal);
		correlation.Left.column("tripNumber");
		correlation.Right.column("identification");

		Assert.contains("CROSS JOIN LATERAL (SELECT * FROM trip_telemetry AS t2 WHERE t2.tripNumber = t0.identification LIMIT 1) AS t1",
			sql(select));
	}

	// ---- the aliases the correlation needs -----------------------------------------------------------

	function testTheBodyIsAliasedApartFromTheOuterQuery() {
		final select = Query.select(Incident)
			.LeftJoinLateral(f -> Query.select(Telemetry).Limit(1))
			.Select((i, a) -> {raisedAt: i.raisedAt})
			.ToExpression();

		final statement = select;
		final body = statement.joinOfType(LeftLateral).Source.asQuery();

		Assert.equals("incidents", statement.selectTableName());
		Assert.equals("trip_telemetry", body.selectTableName());

		// Aliases are given as the statement renders, and the body's table does not take the outer's.
		final rendered = sql(select);
		Assert.contains("FROM incidents AS t0", rendered);
		Assert.contains("FROM trip_telemetry AS t2", rendered);
	}

	// ---- what it refuses to guess at -----------------------------------------------------------------

	function testTheOuterRowUsedAsAValue_IsRefused() {
		Assert.skip("NotSupportedException at build time: the port converts while compiling, so Limit(f.take) "
			+ "is a compile error (LambdaCalls.RefuseOuterValue), not an exception a test can catch");
	}

	function testTheOuterRowPassedAround_IsRefused() {
		Assert.skip("NotSupportedException at build time: the port converts while compiling, so Describe(f) "
			+ "over the outer row is a compile error, not an exception a test can catch");
	}

	// ---- the path that already correlates ------------------------------------------------------------

	function testAnUnnestBody_KeepsTheOuterColumn() {
		Assert.skip("Unnest/FunctionSqlSource: PostgreSQL array functions not ported");
	}
}
