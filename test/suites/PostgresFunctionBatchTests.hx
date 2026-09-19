package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `PostgresFunctionBatchTests.cs`. The PostgreSQL-specific scalar functions on `PostgresFunctions`, none of which the port has. */
class PostgresFunctionBatchTests extends TestCase {
	static inline final Reason = "PostgresFunctions (PostgresFunctionsExtension): PostgreSQL-only functions not ported";

	function testTrig_And_Math() {
		Assert.skip(Reason);
	}

	function testStats_Aggregates() {
		Assert.skip(Reason);
	}

	function testString_Functions() {
		Assert.skip(Reason);
	}

	function testArray_And_Jsonb() {
		Assert.skip(Reason);
	}
}
