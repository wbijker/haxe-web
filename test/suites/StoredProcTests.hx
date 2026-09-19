package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `StoredProcTests.cs`. `StoredProcBody` recording and its T-SQL rendering, and the method-declared routines: routines are not in the port. */
class StoredProcTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testParam_KeepsDeclarationOrder() {
		Assert.skip(Reason);
	}

	function testParam_RendersDirectionAsOutput() {
		Assert.skip(Reason);
	}

	function testProcUpdate_ScalarSet_FlowsParameterInsteadOfInlining() {
		Assert.skip(Reason);
	}

	function testGuardClause_RendersIfReturn() {
		Assert.skip(Reason);
	}

	function testDeclare_WithoutName_AutoGeneratesAndResolves() {
		Assert.skip(Reason);
	}

	function testProcDefine_UsesExplicitName() {
		Assert.skip(Reason);
	}

	function testConcurrentRecording_IsIsolated() {
		Assert.skip(Reason);
	}

	function testApplyCredit_RendersTSql() {
		Assert.skip(Reason);
	}

	// ---- Method-declared routine API (DbStoredProc / DbFunction) ----

	function testDbStoredProc_RendersCreateProcedure_NamedAfterItsMethod() {
		Assert.skip(Reason);
	}

	function testDbStoredProc_ToExecSql_MapsArgumentsToParameters() {
		Assert.skip(Reason);
	}

	function testDbStoredProc_ToExecSql_DefaultsToTheArgumentsItWasCalledWith() {
		Assert.skip(Reason);
	}

	function testDbFunction_RendersCreateFunction() {
		Assert.skip(Reason);
	}
}
