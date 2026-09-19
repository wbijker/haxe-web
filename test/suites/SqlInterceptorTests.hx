package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `SqlInterceptorTests.cs`. Interceptors, seeing statements before they run: nothing of it is in this port. */
class SqlInterceptorTests extends TestCase {
	static final Reason = "Profiler/Logger/Interceptor: not ported";

	function testInterceptor_IsInvoked_ForInsertSelectAndDelete() {
		Assert.skip(Reason);
	}

	function testInterceptor_IsInvoked_ForSchemaChangesDuringAddMigration() {
		Assert.skip(Reason);
	}

	function testInterceptor_ReceivesTheDriver_SoItCanRenderSql() {
		Assert.skip(Reason);
	}

	function testInterceptor_CanRewriteSelect_ToChangeResults() {
		Assert.skip(Reason);
	}

	function testInterceptor_SeesAFunctionCall_BeforeItRuns() {
		Assert.skip(Reason);
	}

	function testInterceptor_SeesAProcedureCall_BeforeItRuns() {
		Assert.skip(Reason);
	}

	function testRoutineCall_CanBeRewritten_WithDifferentArguments() {
		Assert.skip(Reason);
	}
}
