package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.fetchfirstsubquery.Entities;

using codequery.testing.SqlAssert;

/**
	`FetchFirstSubqueryTests.cs` — `FetchFirst()` and `FetchFirstOrDefault()` inside a query's lambda
	are questions for the database about the row being read, not instructions to fetch something now.
**/
class FetchFirstSubqueryTests extends TestCase {
	static function sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	function testItReadsTheOuterRow() {
		final rendered = sql(Query.select(Booking)
			.Select(r -> {id: r.id, rate: Query.select(Unit).Where(u -> u.id == r.unitId).Select(u -> u.baseRateCents).FetchFirst()})
			.ToExpression());

		Assert.contains("(SELECT t1.baseRateCents FROM unit AS t1 WHERE t1.id = t0.unitId LIMIT 1)", rendered);
	}

	function testItIsASubqueryEvenWhenItNamesNoOuterRow() {
		final rendered = sql(Query.select(Booking)
			.Select(r -> {id: r.id, rate: Query.select(Unit).Where(u -> u.sleeps > 2).Select(u -> u.baseRateCents).FetchFirst()})
			.ToExpression());

		Assert.contains("SELECT t1.baseRateCents FROM unit AS t1 WHERE t1.sleeps > 2 LIMIT 1", rendered);
		Assert.doesNotContain("AS rate FROM booking AS t0",
			StringTools.replace(rendered, "LIMIT 1) AS rate FROM booking AS t0", ""));
	}

	function testFetchFirstOrDefaultTranslatesTheSameWay() {
		final rendered = sql(Query.select(Booking)
			.Select(r -> {id: r.id, rate: Query.select(Unit).Where(u -> u.id == r.unitId).Select(u -> u.baseRateCents).FetchFirstOrDefault()})
			.ToExpression());

		Assert.contains("WHERE t1.id = t0.unitId LIMIT 1", rendered);
	}

	function testItWorksInAWhereClause() {
		final rendered = sql(Query.select(Booking)
			.Where(r -> Query.select(Unit).Where(u -> u.id == r.unitId).Select(u -> u.baseRateCents).FetchFirst() > 100)
			.ToExpression());

		Assert.contains("LIMIT 1) > 100", rendered);
	}
}
