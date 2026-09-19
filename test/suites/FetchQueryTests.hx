package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `FetchQueryTests.cs`. */
class FetchQueryTests extends TestCase {
	function testInsert_And_Fetch_RoundTripsRows() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testFetch_WithWhere_FiltersRows() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testFetchFirst_ReturnsFirstRow_WithLimitOne() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testFetchFirst_Throws_WhenNoRows() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testFetchFirstOrDefault_ReturnsFirstRow() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testFetchFirstOrDefault_ReturnsNull_WhenNoRows() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testDelete_Execute_RemovesAllRowsAndReturnsCount() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testDelete_ToSql_RendersDeleteFromTable() {
		// The port aliases the target, as PostgreSQL allows; SQLite's own driver leaves it off.
		final sql = new SqlTranslator().ToSql(Query.table(Person).Delete().ToExpression());
		Assert.startsWith("DELETE FROM people", sql);
	}

	function testRowMapper_CoercesValuesToTargetType() {
		Assert.skip("RowMapper: not ported (rows are read into entities by the PHP runtime)");
	}
}

@tableName("people")
class Person {
	public var id:Int = 0;

	@columnNullable(false)
	public var name:String = "";

	public var email:Null<String>;
	public var age:Int = 0;

	public function new() {}
}
