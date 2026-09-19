package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;
using codequery.testing.SourceAccess;

@tableName("readings")
class ReuseReading {
	public var id:Int = 0;
	public var deviceId:Int = 0;
	public var value:Int = 0;

	public function new() {}
}

/** `QueryReuseTests.cs` — a query used twice: each clause answers with a query of its own. */
class QueryReuseTests extends TestCase {
	function testAddingToOneLeavesTheOther() {
		final open = Query.select(ReuseReading).Where(r -> r.value > 0);

		final forDevice = open.Where(r -> r.deviceId == 1);
		final counted = open.GroupBy(r -> r.deviceId).SelectAggregation(g -> {key: g.key(r -> r.deviceId), total: g.count()});

		final narrowed = forDevice.Select(r -> {id: r.id}).ToExpression().whereBinary(And);
		narrowed.Left.comparison("value", GreaterThan, 0);
		narrowed.Right.comparison("deviceId", Equal, 1);

		// The grouped fork kept only what it was forked from — the device narrowing never reached it.
		final grouped = counted.ToExpression();
		grouped.whereClause().comparison("value", GreaterThan, 0);
		grouped.groupBy().column("deviceId");

		// And the query they were forked from is untouched.
		final original = open.Select(r -> {id: r.id}).ToExpression();
		Assert.equals("readings", original.selectTableName());
		original.whereClause().comparison("value", GreaterThan, 0);
		Assert.empty(original.GroupBy);
	}

	function testSoDoesEveryOtherClause() {
		final all = Query.select(ReuseReading);

		final newest = all.OrderByDesc(r -> r.id).Limit(5);
		final oldest = all.OrderBy(r -> r.id).Limit(1);

		final newestSelect = newest.Select(r -> {id: r.id}).ToExpression();
		newestSelect.orderBy().Expression.column("id");
		Assert.isFalse(newestSelect.orderBy().Ascending);
		Assert.equals(5, newestSelect.Limit);

		final oldestSelect = oldest.Select(r -> {id: r.id}).ToExpression();
		oldestSelect.orderBy().Expression.column("id");
		Assert.isTrue(oldestSelect.orderBy().Ascending);
		Assert.equals(1, oldestSelect.Limit);
	}

	function testAJoinedQueryForksToo() {
		final joined = Query.select(ReuseReading)
			.InnerJoin(Query.select(ReuseReading), (a, b) -> b.deviceId == a.deviceId);

		final narrowed = joined.Where((a, b) -> b.value > a.value);

		final narrowedSelect = narrowed.Select((a, b) -> {id: a.id}).ToExpression();
		Assert.single(narrowedSelect.Joins);
		final comparison = narrowedSelect.whereBinary(GreaterThan);
		comparison.Left.column("value");
		comparison.Right.column("value");
		Assert.notEqual(narrowedSelect.sourceAlias(comparison.Left), narrowedSelect.sourceAlias(comparison.Right));

		// The query it was forked from still has the join and nothing else.
		final joinedSelect = joined.Select((a, b) -> {id: a.id}).ToExpression();
		Assert.single(joinedSelect.Joins);
		Assert.isNull(joinedSelect.Where);
	}

	function testEachForkReturnsItsOwnRows() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testAForkKeepsWhatTheDriverAdded() {
		final locked = Query.select(ReuseReading).Select(r -> {id: r.id}).ForUpdate().SkipLocked();

		final forked = locked.ToExpression();

		Assert.equals(RowLockMode.Update, forked.Lock);
		Assert.isTrue(forked.LockSkipLocked);
	}
}
