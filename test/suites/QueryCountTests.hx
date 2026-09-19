package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("parts")
class CountPart {
	public var id:Int = 0;
	public var kind:String = "";

	public function new() {}
}

/**
	`QueryCountTests.cs` — `Count()`: how many rows the query returns. The C# tests write rows and
	read the count back, which needs a database; the ones about the SQL the count is asked as are
	rendered here from `CountExpression()`, the statement `Count()` would run.
**/
class QueryCountTests extends TestCase {
	static final NeedsDb = "needs a database: eval has none (PHP runtime only)";

	static function parts():DbTable<CountPart> {
		return Query.table(CountPart);
	}

	static function sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	function testEveryRow() {
		Assert.skip(NeedsDb);
	}

	function testOnlyTheFilteredRows() {
		Assert.skip(NeedsDb);
	}

	function testALimitIsHonoured() {
		Assert.skip(NeedsDb);
	}

	function testADistinctIsHonoured() {
		Assert.skip(NeedsDb);
	}

	function testAGroupingCountsGroups() {
		Assert.skip(NeedsDb);
	}

	function testNoRowsIsZero() {
		Assert.skip(NeedsDb);
	}

	function testItAgreesWithFetch() {
		Assert.skip(NeedsDb);
	}

	// --- The SQL the count is asked as ---------------------------------------------------------------

	function testItIsTheQueryWithCountInPlaceOfItsProjection() {
		final last = sql(parts().From().Where(p -> p.kind == "bolt").CountExpression());

		Assert.startsWith("SELECT COUNT(*) FROM parts AS t0 WHERE", last);
		Assert.doesNotContain("FROM (", last);
	}

	function testAnOrderByIsDroppedFromTheCount() {
		// The number itself needs a database; the statement it would run does not.
		final last = sql(parts().From().OrderBy(p -> p.kind).CountExpression());

		Assert.doesNotContain("ORDER BY", last);
	}

	function testALimitIsCountedFromASubquery() {
		final last = sql(parts().From().Limit(2).CountExpression());

		Assert.startsWith("SELECT COUNT(*) FROM (", last);
	}

	function testADistinctAndAGroupingAreCountedFromASubquery() {
		final distinct = sql(parts().From().Select(p -> {kind: p.kind}).Distinct().CountExpression());
		Assert.startsWith("SELECT COUNT(*) FROM (", distinct);

		final grouped = sql(parts().From()
			.GroupBy(p -> p.kind)
			.SelectAggregation(a -> {kind: a.key(p -> p.kind), parts: a.count()})
			.CountExpression());
		Assert.startsWith("SELECT COUNT(*) FROM (", grouped);
	}

	function testAnAggregatingProjectionCountsItsOneRow() {
		// That the count is one needs a database; that it is asked of the aggregated row does not.
		final last = sql(parts().From().SelectAggregation(a -> {rows: a.count()}).CountExpression());

		Assert.startsWith("SELECT COUNT(*) FROM (", last);
	}
}
