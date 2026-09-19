package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/BinaryCopyIntegrationTests.cs`. */
class Integration_BinaryCopyIntegrationTests extends TestCase {
	static final Reason = "BinaryCopy: not ported";

	function testPostgres_BinaryCopy_StreamsTypedRows() {
		Assert.skip(Reason);
	}

	function testSqlServer_BinaryCopy_StreamsTypedRows() {
		Assert.skip(Reason);
	}
}
