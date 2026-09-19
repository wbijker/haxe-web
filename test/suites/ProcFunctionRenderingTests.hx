package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `ProcFunctionRenderingTests.cs`. Scalar functions inside a routine body, per dialect: routines are not in the port. */
class ProcFunctionRenderingTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testDateArithmeticOverAParameter_RendersAsDateAdd() {
		Assert.skip(Reason);
	}

	function testChainedDateArithmetic_NestsInTheOrderItWasWritten() {
		Assert.skip(Reason);
	}

	function testStringFunctions_RenderPerDialect() {
		Assert.skip(Reason);
	}

	function testNumericFunctions_Render() {
		Assert.skip(Reason);
	}

	function testPostgresDateArithmetic_MultipliesAUnitInterval_SoAParameterWorks() {
		Assert.skip(Reason);
	}

	// --- The renderers directly ---

	function testDateParts_RenderPerDialect() {
		Assert.skip("SqlRoutineRenderer/PostgresProcRenderer: routine body renderers not ported");
	}

	function testAFunctionTheBodyRendererDoesNotKnow_SaysSoRatherThanEmittingWrongSql() {
		Assert.skip("SqlRoutineRenderer/PostgresProcRenderer: routine body renderers not ported");
	}
}
