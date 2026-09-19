package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `RuntimeSettingTests.cs`. `db.Set(...)` — every setting the C# tests use is pg_trgm's. */
class RuntimeSettingTests extends TestCase {
	static final Reason = "PgTrgm: PostgreSQL extension";

	function testASettingIsWrittenByTheExtensionThatDeclaredIt() {
		Assert.skip(Reason);
	}

	function testASettingIsScopedToTheTransactionByDefault() {
		Assert.skip(Reason);
	}

	function testAScopedSettingOutsideATransactionIsRefused() {
		Assert.skip(Reason);
	}

	function testTheSameNameReadsItAndSetsIt() {
		Assert.skip(Reason);
	}
}
