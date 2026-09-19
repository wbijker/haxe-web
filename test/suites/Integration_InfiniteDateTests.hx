package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/InfiniteDateTests.cs`. */
class Integration_InfiniteDateTests extends TestCase {
	static final Reason = "needs a database: eval has none (PHP runtime only)";

	function testTheColumnItselfAlreadyCarriesBothEnds() {
		Assert.skip(Reason);
	}

	function testAskingAnInfiniteDateForItsYear_NoLongerFailsTheFetch() {
		Assert.skip(Reason);
	}

	function testAndTheSameReadAsANullable() {
		Assert.skip(Reason);
	}

	function testTheTwoEndsStayApart() {
		Assert.skip(Reason);
	}

	function testSomeOperationsFailOnTheServer_WhereNoNetCanReachThem() {
		Assert.skip(Reason);
	}

	function testANumberThatIsNotOne_ReadsAsItsEnd_RatherThanStoppingTheRead() {
		Assert.skip(Reason);
	}

	function testAnOrdinaryDateIsUnaffected() {
		Assert.skip(Reason);
	}
}
