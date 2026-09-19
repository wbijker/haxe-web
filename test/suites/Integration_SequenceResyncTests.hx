package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/SequenceResyncTests.cs`. */
class Integration_SequenceResyncTests extends TestCase {
	static final Reason = "needs a database: eval has none (PHP runtime only)";

	function testABulkCopyOfBorrowedKeys_KeepsThem_AndLeavesTheSequencePastThem() {
		Assert.skip(Reason);
	}

	function testWithoutTheResync_TheSequenceIsStillAtTheStart_AndTheNextInsertCollides() {
		Assert.skip(Reason);
	}

	function testALoadKnowsItsOwnKeys_TheTableKnowsThemAll() {
		Assert.skip(Reason);
	}

	function testAnOrdinaryInsertResyncs_JustAsTheCopyDoes() {
		Assert.skip(Reason);
	}

	function testSetSequence_PutsTheCounterWhereItIsTold_AndSaysWhereThatIs() {
		Assert.skip(Reason);
	}

	function testTheCallsWorkForASerialColumnToo_ItsSequenceBeingFoundTheSameWay() {
		Assert.skip(Reason);
	}

	function testResyncingAnEmptyTable_PutsTheSequenceBackToTheStart() {
		Assert.skip(Reason);
	}
}
