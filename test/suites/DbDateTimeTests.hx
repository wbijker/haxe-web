package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DbDateTimeTests.cs` — `[DbDateTime]`, what a timestamp column's values mean. Not in this port. */
class DbDateTimeTests extends TestCase {
	function testAUtcColumn_ComesBackKnowingItIsUtc() {
		Assert.skip("DbDateTime: storage kind of a timestamp column not ported; needs a database: eval has none (PHP runtime only)");
	}

	function testALocalValueWrittenToAUtcColumn_IsConverted_NotRelabelled() {
		Assert.skip("DbDateTime: storage kind of a timestamp column not ported; needs a database: eval has none (PHP runtime only)");
	}

	function testSayingNothing_ChangesNothing() {
		Assert.skip("DbDateTime: storage kind of a timestamp column not ported; needs a database: eval has none (PHP runtime only)");
	}

	function testItChangesTheValue_NotTheColumn() {
		Assert.skip("DbDateTime: storage kind of a timestamp column not ported");
	}

	function testOnSomethingThatIsNotADateTime_ItSaysSo() {
		Assert.skip("DbDateTime: storage kind of a timestamp column not ported; DateTimeOffset: no zoned date type in this port");
	}
}
