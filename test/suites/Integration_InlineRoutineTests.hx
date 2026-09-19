package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/InlineRoutineTests.cs`. */
class Integration_InlineRoutineTests extends TestCase {
	static final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testARebuiltDatabaseHasBothKindsOfFunction() {
		Assert.skip(Reason);
	}

	function testApplyingThemAgainReplacesWhatIsThere() {
		Assert.skip(Reason);
	}

	function testOneDroppedByHandIsBackAfterTheNextStart() {
		Assert.skip(Reason);
	}
}
