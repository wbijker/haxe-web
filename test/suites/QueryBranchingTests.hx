package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.queries.ISelectQuery;
import codequery.sqldrivers.NormalizedSqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("booking")
class BranchBooking {
	public var id:Int = 0;
	public var unitId:Int = 0;
	public var total:Int = 0;

	public function new() {}
}

/**
	`QueryBranchingTests.cs` — a query is a value: adding a clause answers with a new query and
	leaves the one it was asked of alone.
**/
class QueryBranchingTests extends TestCase {
	static function bookings():DbTable<BranchBooking> {
		return Query.table(BranchBooking);
	}

	static function sql(q:ISelectQuery<BranchBooking>):String {
		return new NormalizedSqlTranslator().ToSql(q.ToExpression());
	}

	function testTwoBranchesOffOneBase_AreTwoQueries() {
		final f = bookings().From();

		final a = f.Where(b -> b.id == 1);
		final b = f.Where(x -> x.id == 2);

		Assert.contains("= 1", sql(a));
		Assert.doesNotContain("= 2", sql(a));

		Assert.contains("= 2", sql(b));
		Assert.doesNotContain("= 1", sql(b));
	}

	function testTheBaseIsUnchangedByWhatWasBuiltOnIt() {
		final f = bookings().From();

		f.Where(b -> b.id == 1);

		Assert.doesNotContain("WHERE", sql(f));
	}

	function testALimitOnOneBranchIsNotOnTheOther() {
		final f = bookings().From();

		final limited = f.Limit(10);

		Assert.contains("LIMIT 10", sql(limited));
		Assert.doesNotContain("LIMIT", sql(f));
	}

	function testFetchFirstDoesNotLimitTheQueryForever() {
		Assert.skip("FetchFirstOrDefault: needs a database: eval has none (PHP runtime only)");
	}

	function testNoClauseReachesBackIntoTheQueryItWasAddedTo() {
		final clauses:Array<{name:String, add:ISelectQuery<BranchBooking>->Dynamic}> = [
			{name: "Where", add: (q:ISelectQuery<BranchBooking>) -> q.Where(b -> b.id == 1)},
			{name: "OrderBy", add: (q:ISelectQuery<BranchBooking>) -> q.OrderBy(b -> b.total)},
			{name: "OrderByDesc", add: (q:ISelectQuery<BranchBooking>) -> q.OrderByDesc(b -> b.total)},
			{name: "Limit", add: (q:ISelectQuery<BranchBooking>) -> q.Limit(5)},
			{name: "Offset", add: (q:ISelectQuery<BranchBooking>) -> q.Offset(5)},
			{name: "Distinct", add: (q:ISelectQuery<BranchBooking>) -> q.Distinct()},
			{name: "DistinctOn", add: (q:ISelectQuery<BranchBooking>) -> q.Distinct(b -> b.unitId)},
			{name: "GroupBy", add: (q:ISelectQuery<BranchBooking>) -> q.GroupBy(b -> b.unitId)},
			{name: "Select", add: (q:ISelectQuery<BranchBooking>) -> q.Select(b -> {id: b.id})},
			{name: "InnerJoin", add: (q:ISelectQuery<BranchBooking>) -> q.InnerJoin(bookings(), (a, b) -> a.id == b.id)},
			{name: "LeftJoin", add: (q:ISelectQuery<BranchBooking>) -> q.LeftJoin(bookings(), (a, b) -> a.id == b.id)},
			{name: "WhereExists", add: (q:ISelectQuery<BranchBooking>) -> q.WhereExists(bookings(), (a, b) -> a.id == b.id)},
			{name: "AsCte", add: (q:ISelectQuery<BranchBooking>) -> q.AsCte("c")},
		];

		for (clause in clauses) {
			final basis = bookings().From();
			final before = sql(basis);

			clause.add(basis);

			Assert.equals(before, sql(basis), clause.name);
		}
	}

	function testAnOrderingOnOneBranchIsNotOnTheOther() {
		final f = bookings().From();

		final ordered = f.OrderBy(b -> b.total);

		Assert.contains("ORDER BY", sql(ordered));
		Assert.doesNotContain("ORDER BY", sql(f));
	}
}
