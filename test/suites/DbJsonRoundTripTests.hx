package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DbJsonRoundTripTests.cs`. Reading a JSON column back into a `DbJson` through `RowMapper`: JSON is not in the port. */
class DbJsonRoundTripTests extends TestCase {
	static inline final Reason = "DbJson/RowMapper: JSON not ported";

	function testTextBecomesTheDocument() {
		Assert.skip(Reason);
	}

	function testAParsedDocumentBecomesTheDocument() {
		Assert.skip(Reason);
	}

	function testADbJsonIsPassedThrough() {
		Assert.skip(Reason);
	}

	function testNullStaysNull() {
		Assert.skip(Reason);
	}
}
