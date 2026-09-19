package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `ProcDslGapTests.cs`. The T-SQL procedure DSL (TRY/CATCH, THROW, PRINT, EXEC, cursors and the rest): routines are not in the port. */
class ProcDslGapTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testTryCatch_WithTransactionAndRethrow() {
		Assert.skip(Reason);
	}

	function testThrow_WithNumberMessageState() {
		Assert.skip(Reason);
	}

	function testAssign_LocalFromSubquery() {
		Assert.skip(Reason);
	}

	function testAssign_OutputParameter_FromScalarAndSubquery() {
		Assert.skip(Reason);
	}

	function testReturn_ScalarExpression() {
		Assert.skip(Reason);
	}

	function testPrint_LiteralAndExpression() {
		Assert.skip(Reason);
	}

	function testWhileExists_WithBreak_AndBatchDelete() {
		Assert.skip(Reason);
	}

	function testContinue_Renders() {
		Assert.skip(Reason);
	}

	function testBareSelect_ReturnsResultSet() {
		Assert.skip(Reason);
	}

	function testSetNoCount_RendersPreamble() {
		Assert.skip(Reason);
	}

	function testExec_CallsNestedProcedure_WithArgs() {
		Assert.skip(Reason);
	}

	function testExec_NoArgs() {
		Assert.skip(Reason);
	}

	function testFunction_ReturnsScalarSubquery() {
		Assert.skip(Reason);
	}

	function testElseIf_Chain_RendersLadder() {
		Assert.skip(Reason);
	}

	function testComment_RendersALineComment_AtTheStatementsIndent() {
		Assert.skip(Reason);
	}

	function testComment_CommentsEveryLineOfAMultiLineText() {
		Assert.skip(Reason);
	}

	function testComment_InsideABranch_TakesThatBranchesIndent() {
		Assert.skip(Reason);
	}
}
