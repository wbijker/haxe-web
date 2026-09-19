package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/IdentityIntegrationTests.cs`. */
class Integration_IdentityIntegrationTests extends TestCase {
	static final Reason = "needs a database: eval has none (PHP runtime only)";

	function testAnAlwaysColumn_TakesAKeyOfTheCallersOwn_BecauseTheInsertSaysSo() {
		Assert.skip(Reason);
	}

	function testAnAlwaysColumn_StillGeneratesTheKeyForARowThatCarriesNone() {
		Assert.skip(Reason);
	}

	function testASerialColumn_TakesAnExplicitKeyWithoutCeremony() {
		Assert.skip(Reason);
	}

	function testALoadOfBorrowedKeys_CollidesWithTheNextGeneratedOne_UnlessTheSequenceIsTold() {
		Assert.skip(Reason);
	}

	function testPrimaryKeyResync_LeavesTheSequenceWhereTheLoadLeftTheKeys() {
		Assert.skip(Reason);
	}

	function testSetSequence_PutsTheCounterWhereItIsTold() {
		Assert.skip(Reason);
	}

	function testAColumnWithNoSequenceBehindIt_IsSaidSoRatherThanQuietlyIgnored() {
		Assert.skip(Reason);
	}
}
