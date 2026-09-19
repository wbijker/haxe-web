package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `PostgresProcTests.cs`. `StoredProcBody` rendered to PL/pgSQL: routines are not in the port. */
class PostgresProcTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testApplyCredit_RendersPlPgSql() {
		Assert.skip(Reason);
	}

	function testElseIf_RendersElsifChain() {
		Assert.skip(Reason);
	}

	function testWhile_RendersLoop() {
		Assert.skip(Reason);
	}

	function testForRange_RendersForLoop() {
		Assert.skip(Reason);
	}

	function testForRange_Reverse_RendersReverse() {
		Assert.skip(Reason);
	}

	function testForEach_RendersForeachArray() {
		Assert.skip(Reason);
	}

	function testLoop_WithExit_RendersLoop() {
		Assert.skip(Reason);
	}

	function testRaise_RendersRaiseWithLevel() {
		Assert.skip(Reason);
	}

	function testReturnQuery_RendersReturnQuery() {
		Assert.skip(Reason);
	}

	function testCursor_DeclareOpenFetchClose() {
		Assert.skip(Reason);
	}

	function testTryCatch_RendersExceptionBlock() {
		Assert.skip(Reason);
	}
}
