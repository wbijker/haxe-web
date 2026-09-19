package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `FunctionVisitorRegistrationTests.cs` — registering function visitors on a configuration. */
class FunctionVisitorRegistrationTests extends TestCase {
	function testAddFunctionVisitor_Generic_AddsToConfiguration() {
		Assert.skip("IFunctionVisitor: runtime function visitors not ported (the converter runs while compiling)");
	}

	function testAddFunctionVisitor_ReturnsConfiguration_ForChaining() {
		Assert.skip("IFunctionVisitor: runtime function visitors not ported; Profiler/Logger/Interceptor: not ported");
	}

	function testAddFunctionVisitor_AlsoRegistersGlobalFallback() {
		Assert.skip("IFunctionVisitor: runtime function visitors not ported (the converter runs while compiling)");
	}

	function testConfiguration_ExposesMeta() {
		Assert.skip("DatabaseMeta: a configuration's entity metadata is not ported (columns are read while compiling)");
	}
}
