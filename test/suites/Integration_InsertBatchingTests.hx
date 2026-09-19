package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/InsertBatchingTests.cs`. */
class Integration_InsertBatchingTests extends TestCase {
	static final Reason = "needs a database: eval has none (PHP runtime only)";

	function testMoreRowsThanAStatementCanBind() {
		Assert.skip(Reason);
	}

	function testTheRowsThatLandAreTheRowsGiven() {
		Assert.skip(Reason);
	}

	function testABatchSizeOfZeroIsOneStatement() {
		Assert.skip(Reason);
	}

	function testABulkCopyIsNotCutUp() {
		Assert.skip(Reason);
	}

	function testKeysComeBackOntoTheRightRows() {
		Assert.skip(Reason);
	}
}
