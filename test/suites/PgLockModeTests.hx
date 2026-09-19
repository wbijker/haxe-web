package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

class PgLockRow {
	public var id:Int = 0;

	public function new() {}
}

/** `PgLockModeTests.cs` — `FOR NO KEY UPDATE` / `FOR KEY SHARE`. */
class PgLockModeTests extends TestCase {
	function testForNoKeyUpdate_SkipLocked() {
		final q = Query.select(PgLockRow).ForNoKeyUpdate().SkipLocked();
		Assert.endsWith("FOR NO KEY UPDATE SKIP LOCKED", new SqlTranslator().ToSql(q.ToExpression()));
	}

	function testForKeyShare_Renders() {
		final q = Query.select(PgLockRow).ForKeyShare();
		Assert.endsWith("FOR KEY SHARE", new SqlTranslator().ToSql(q.ToExpression()));
	}
}
