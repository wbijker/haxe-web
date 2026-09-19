package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`PostgresFunctionsTests.cs`.

	`PostgresFunctions` are the PostgreSQL-only built-ins (JSONB, arrays, = ANY, …) rendered by a
	driver extension registered process-wide. The port has no extension registry and none of them.
**/
class PostgresFunctionsTests extends TestCase {
	static inline final Reason = "PostgresFunctions (PostgresFunctionsExtension): PostgreSQL-only functions not ported";

	function testExtension_SelfRegisters_ViaModuleInitializer() {
		Assert.skip(Reason);
	}

	function testPlainFunction_RendersThroughExtension() {
		Assert.skip(Reason);
	}

	function testOperatorFunction_RendersThroughCustomExpression() {
		Assert.skip(Reason);
	}

	function testBuiltIns_AreNotAConfigurationExtension_SoNoCreateExtension() {
		Assert.skip(Reason);
	}
}
