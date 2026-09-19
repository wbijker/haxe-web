package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `ComplexProcTests.cs`. Whole procedures rendered to T-SQL: routines are not in the port. */
class ComplexProcTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testTransferFunds_RendersTransactionWithGuards() {
		Assert.skip(Reason);
	}

	function testUpsertBalance_RendersIfExistsElse() {
		Assert.skip(Reason);
	}

	function testClassifyAccount_RendersBranchedLocalAssignment() {
		Assert.skip(Reason);
	}
}
