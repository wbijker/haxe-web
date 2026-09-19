package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

class ForUpdateRow {
	public var id:Int = 0;

	public function new() {}
}

/** `ForUpdateTests.cs` — `SELECT … FOR UPDATE` row locking across dialects; this port renders the one. */
class ForUpdateTests extends TestCase {
	function testPostgres_ForUpdate_SkipLocked() {
		final query = Query.select(ForUpdateRow).Where(r -> r.id > 0).ForUpdate().SkipLocked();

		Assert.endsWith("FOR UPDATE SKIP LOCKED", new SqlTranslator().ToSql(query.ToExpression()));
	}

	function testMySql_ForShare() {
		final query = Query.select(ForUpdateRow).ForShare();
		Assert.endsWith("FOR SHARE", new SqlTranslator().ToSql(query.ToExpression()));
	}

	function testSqlite_And_SqlServer_Throw() {
		Assert.skip("SqliteSqlDriver/MssqlSqlDriver: refusing FOR UPDATE is those dialects' own; this port has the one dialect, which renders it");
	}
}
