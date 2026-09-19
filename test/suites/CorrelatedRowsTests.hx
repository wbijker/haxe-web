package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`CorrelatedRowsTests.cs`.

	`DbQuery.CorrelatedRows` gathers a subquery's rows into one JSON value per outer row, which is
	JSON end to end — the expression, every dialect's spelling of it, and reading it back.
**/
class CorrelatedRowsTests extends TestCase {
	function testTheCollectionIsACorrelatedSubqueryGatheredIntoOneValue() {
		Assert.skip("JsonExpression: JSON not ported (CorrelatedRows gathers the rows as a JsonAggregateSqlExpression)");
	}

	function testPostgresAggregatesTheRow() {
		Assert.skip("JsonExpression: JSON not ported (PostgresSqlDriver's json_agg of the correlated rows)");
	}

	function testSqliteBuildsEachObject() {
		Assert.skip("JsonExpression: JSON not ported (SqliteSqlDriver's json_group_array of the correlated rows)");
	}

	function testMySqlBuildsEachObject() {
		Assert.skip("JsonExpression: JSON not ported (MySqlSqlDriver's JSON_ARRAYAGG of the correlated rows)");
	}

	function testSqlServerWritesTheResultOut() {
		Assert.skip("JsonExpression: JSON not ported (MssqlSqlDriver's FOR JSON PATH of the correlated rows)");
	}

	function testEachRowCarriesItsOwn() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testOutsideALambdaItSaysSo() {
		Assert.skip("JsonExpression: JSON not ported (CorrelatedRows has no counterpart here to call outside a lambda)");
	}
}
