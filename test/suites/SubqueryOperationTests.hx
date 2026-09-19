package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.subqueryoperation.Entities;

using codequery.testing.SqlAssert;

/**
	`SubqueryOperationTests.cs` — the questions one asks of a subquery, in the words LINQ taught:
	`Any`, `All`, `Contains`, `Sum`, `Count`, `FirstOrDefault`. Each reads the row around it and
	becomes the SQL that asks that question, in the one statement rather than a second one.
**/
class SubqueryOperationTests extends TestCase {
	static function sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	// --- Asking whether ------------------------------------------------------------------------------

	function testAnyIsExists() {
		Assert.contains(
			"WHERE EXISTS (SELECT * FROM orders AS t1 WHERE t1.customerId = t0.id)",
			sql(Query.select(Customer)
				.Where(c -> Query.select(Order).Where(o -> o.customerId == c.id).Any())
				.Select(c -> {id: c.id})
				.ToExpression()));
	}

	function testAnyTakesAPredicate() {
		Assert.contains(
			"EXISTS (SELECT * FROM orders AS t1 WHERE t1.customerId = t0.id AND t1.total > 100)",
			sql(Query.select(Customer)
				.Where(c -> Query.select(Order).Any(o -> o.customerId == c.id && o.total > 100))
				.Select(c -> {id: c.id})
				.ToExpression()));
	}

	function testAllLooksForOneThatDoesNot() {
		Assert.contains(
			"NOT EXISTS (SELECT * FROM orders AS t1 WHERE t1.customerId = t0.id AND NOT (t1.total > 0))",
			sql(Query.select(Customer)
				.Where(c -> Query.select(Order).Where(o -> o.customerId == c.id).All(o -> o.total > 0))
				.Select(c -> {id: c.id})
				.ToExpression()));
	}

	function testItIsAnOrdinaryCondition() {
		final rendered = sql(Query.select(Customer)
			.Where(c -> !Query.select(Order).Where(o -> o.customerId == c.id).Any() || c.name == "house")
			.Select(c -> {id: c.id})
			.ToExpression());

		Assert.contains("NOT (EXISTS (SELECT * FROM orders", rendered);
		Assert.contains(" OR ", rendered);
	}

	function testContainsIsIn() {
		Assert.contains(
			"WHERE t0.id IN (SELECT t1.customerId FROM orders AS t1)",
			sql(Query.select(Customer)
				.Where(c -> Query.select(Order).Select(o -> o.customerId).Contains(c.id))
				.Select(c -> {id: c.id})
				.ToExpression()));
	}

	// --- Asking how much -----------------------------------------------------------------------------

	function testTheAggregatesAreScalarSubqueries() {
		final rendered = sql(Query.select(Customer)
			.Select(c -> {
				name: c.name,
				spend: Query.select(Order).Where(o -> o.customerId == c.id).Sum(o -> o.total),
				biggest: Query.select(Order).Where(o -> o.customerId == c.id).Max(o -> o.total),
				smallest: Query.select(Order).Where(o -> o.customerId == c.id).Min(o -> o.total),
				mean: Query.select(Order).Where(o -> o.customerId == c.id).Avg(o -> o.total),
			})
			.ToExpression());

		Assert.contains("(SELECT SUM(t1.total) FROM orders AS t1 WHERE t1.customerId = t0.id) AS spend", rendered);
		Assert.contains("MAX(", rendered);
		Assert.contains("MIN(", rendered);
		Assert.contains("AVG(", rendered);
	}

	function testCountInsideALambdaIsASubquery() {
		Assert.contains(
			"(SELECT COUNT(*) FROM orders AS t1 WHERE t1.customerId = t0.id) AS n",
			sql(Query.select(Customer)
				.Select(c -> {n: Query.select(Order).Where(o -> o.customerId == c.id).Count()})
				.ToExpression()));
	}

	// --- Asking for the rows themselves --------------------------------------------------------------

	function testFirstOrDefaultTakesOneValue() {
		Assert.contains(
			"(SELECT t1.ref FROM orders AS t1 WHERE t1.customerId = t0.id ORDER BY t1.total DESC LIMIT 1) AS biggest",
			sql(Query.select(Customer)
				.Select(c -> {
					biggest: Query.select(Order).Where(o -> o.customerId == c.id)
						.OrderByDesc(o -> o.total).Select(o -> o.ref).FirstOrDefault(),
				})
				.ToExpression()));
	}

	function testToListGathersTheRows() {
		Assert.skip("JsonExpression: JSON not ported (ToList gathers the rows with json_agg)");
	}

	function testTakingOneValueFromAWholeRowSaysSo() {
		final select = Query.select(Customer)
			.Select(c -> {any: Query.select(Order).Where(o -> o.customerId == c.id).FirstOrDefault()})
			.ToExpression();

		final error = Assert.throwsMessage(() -> sql(select));

		Assert.contains("takes one value from each row", error);
		Assert.contains("ToList()", error);
	}

	function testOutsideAQueryItSaysSo() {
		Assert.throws(() -> Query.select(Order).Any());
	}

	// --- Against a database --------------------------------------------------------------------------

	function testTheAnswersAreRight() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
