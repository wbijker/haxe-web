package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `ProcLocalNullTests.cs`. A routine local tested for NULL, and the routine's migration: routines are not in the port. */
class ProcLocalNullTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testTheGuardAsksTheDatabase() {
		Assert.skip(Reason);
	}

	function testSoDoesItsNegation() {
		Assert.skip(Reason);
	}

	function testARoutineIsCreatedSoItCanBeReplaced() {
		Assert.skip(Reason);
	}
}
