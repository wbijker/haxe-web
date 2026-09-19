package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `BinaryCopyTests.cs`. Binary bulk copy, and which dialects have it. */
class BinaryCopyTests extends TestCase {
	static final Reason = "BinaryCopy: not ported";

	function testPostgresAndSqlServer_SupportBinaryCopy() {
		Assert.skip(Reason);
	}

	function testSqliteAndMySql_DoNotSupportBinaryCopy() {
		Assert.skip(Reason);
	}

	function testBulkStrategy_DefaultsToBinaryCopy() {
		Assert.skip(Reason);
	}

	function testBulkCopyRequest_ExposesItsPayload() {
		Assert.skip(Reason);
	}

	function testSqliteExecutor_BinaryCopy_ThrowsAsUnsupported() {
		Assert.skip(Reason);
	}

	function testMySqlExecutor_BinaryCopy_ThrowsAsUnsupported() {
		Assert.skip(Reason);
	}

	function testInsert_BinaryCopy_OnSqlite_FallsBackAndPersists() {
		Assert.skip(Reason);
	}
}
