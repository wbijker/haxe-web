package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/MergeTests.cs`. */
class Integration_MergeTests extends TestCase {
	static final Reason = "needs a database: eval has none (PHP runtime only)";

	function testItUpdatesWhatMatchedAndInsertsWhatDidNot() {
		Assert.skip(Reason);
	}

	function testTheGeneratedKeyIsLeftToTheDatabase() {
		Assert.skip(Reason);
	}

	function testOneRowMergesToo() {
		Assert.skip(Reason);
	}

	function testMatchedRowsCanBeDeleted() {
		Assert.skip(Reason);
	}
}
