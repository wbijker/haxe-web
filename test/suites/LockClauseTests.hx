package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("jobs")
class LockJob {
	public var id:Int = 0;
	public var status:String = "";
	public var ownerId:Int = 0;

	public function new() {}
}

@tableName("owners")
class LockOwner {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

/**
	`LockClauseTests.cs` — row locking: `FOR UPDATE OF t0 SKIP LOCKED`.

	C# replaces the statement with a `SelectExpressionLocked` carrying `Mode`, `Wait` and `Tables`;
	here the statement itself carries `Lock`, `LockSkipLocked`/`LockNoWait` and `LockTables`.
**/
class LockClauseTests extends TestCase {
	static function jobs():DbTable<LockJob> {
		return Query.table(LockJob);
	}

	static function owners():DbTable<LockOwner> {
		return Query.table(LockOwner);
	}

	// ---- the modes -------------------------------------------------------------------------------------

	function testEachModeIsItsOwnLock() {
		Assert.equals(RowLockMode.Update, Query.select(LockJob).ForUpdate().ToExpression().Lock);
		Assert.equals(RowLockMode.NoKeyUpdate, Query.select(LockJob).ForNoKeyUpdate().ToExpression().Lock);
		Assert.equals(RowLockMode.Share, Query.select(LockJob).ForShare().ToExpression().Lock);
		Assert.equals(RowLockMode.KeyShare, Query.select(LockJob).ForKeyShare().ToExpression().Lock);
	}

	function testTheLastModeWins() {
		Assert.equals(RowLockMode.Share, Query.select(LockJob).ForUpdate().ForShare().ToExpression().Lock);
	}

	function testItComesLast() {
		final sql = new SqlTranslator().ToSql(Query.select(LockJob)
			.Where(j -> j.status == "queued")
			.OrderBy(j -> j.id)
			.Limit(1)
			.ForUpdate()
			.ToExpression());

		Assert.equals("SELECT * FROM jobs AS t0 WHERE t0.status = 'queued' ORDER BY t0.id ASC LIMIT 1 FOR UPDATE", sql);
	}

	// ---- what to do about rows someone else holds -------------------------------------------------------

	function testSkippingAndFailing() {
		final skipping = Query.select(LockJob).ForUpdate().SkipLocked().ToExpression();
		Assert.isTrue(skipping.LockSkipLocked);
		Assert.isFalse(skipping.LockNoWait);

		final failing = Query.select(LockJob).ForShare().NoWait().ToExpression();
		Assert.isTrue(failing.LockNoWait);
		Assert.isFalse(failing.LockSkipLocked);
		Assert.equals(RowLockMode.Share, failing.Lock);
	}

	function testOneWaitBehaviourAtATime() {
		final locked = Query.select(LockJob).ForUpdate().SkipLocked().NoWait().ToExpression();
		Assert.isTrue(locked.LockNoWait);
		Assert.isFalse(locked.LockSkipLocked);
	}

	function testSayingItWithoutALock_IsRefused() {
		final skip = Assert.throwsMessage(() -> Query.select(LockJob).SkipLocked());
		Assert.contains("has not taken one", skip);

		Assert.throws(() -> Query.select(LockJob).NoWait());
		Assert.throws(() -> jobs().From().OfTable(jobs()));
	}

	// ---- which rows ------------------------------------------------------------------------------------

	function testOfTableNamesTheAliasTheStatementUses() {
		final locked = jobs().From().Where(j -> j.id > 0).ForUpdate().OfTable(jobs()).ToExpression();

		Assert.equals(locked.Source.Alias, Assert.single(locked.LockTables).Alias);
	}

	function testOfTableAcrossAJoin() {
		// C# folds the join to one row with Reduce first, since its lock extensions are declared on
		// the one-row query; here every arity takes a lock, so the join is locked as it stands.
		final locked = jobs().From()
			.InnerJoin(owners(), (j, o) -> j.ownerId == o.id)
			.ForUpdate()
			.OfTable(jobs())
			.SkipLocked()
			.ToExpression();

		// Both tables are still sources of this statement — which is what lets the lock name one of them.
		Assert.equals("jobs", locked.selectTableName());
		Assert.equals("owners", locked.joinedTableName());

		Assert.equals(locked.Source.Alias, Assert.single(locked.LockTables).Alias);
		Assert.isTrue(locked.LockSkipLocked);
		Assert.endsWith("FOR UPDATE OF t0 SKIP LOCKED", new SqlTranslator().ToSql(locked));
	}

	function testNamingTheSameTableTwiceIsOneLock() {
		final locked = jobs().From().ForUpdate().OfTable(jobs()).OfTable(jobs()).SkipLocked().ToExpression();

		Assert.equals(locked.Source.Alias, Assert.single(locked.LockTables).Alias);
	}

	function testOfATableTheQueryDoesNotRead_IsRefused() {
		final error = Assert.throwsMessage(() -> jobs().From().ForUpdate().OfTable(owners()));

		Assert.contains("does not select from 'owners'", error);
	}

	// ---- what the statement carries --------------------------------------------------------------------

	function testTheQueryCarriesOn() {
		final locked = Query.select(LockJob)
			.ForUpdate()
			.Where(j -> j.status == "queued")
			.OrderByDesc(j -> j.id)
			.ToExpression();

		locked.whereClause().comparison("status", Equal, "queued");
		locked.orderBy().Expression.column("id");
		Assert.isFalse(locked.orderBy().Ascending);
		Assert.equals(RowLockMode.Update, locked.Lock);
	}

	function testTheExpressionSaysSo() {
		final expression = Query.select(LockJob).ForUpdate().SkipLocked().ToExpression();

		Assert.equals(RowLockMode.Update, expression.Lock);
		Assert.isTrue(expression.LockSkipLocked);
		Assert.empty(expression.LockTables);
	}
}
