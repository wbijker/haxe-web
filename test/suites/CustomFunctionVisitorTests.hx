package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`CustomFunctionVisitorTests.cs` — a user-registered `IFunctionVisitor` translating a placeholder
	method call. The C# converter reads a runtime expression tree, which a visitor can be handed; this
	port converts a lambda while compiling, so there is no tree at run time for a visitor to see.
**/
class CustomFunctionVisitorTests extends TestCase {
	function testCustomVisitor_TranslatesCall() {
		Assert.skip("IFunctionVisitor: runtime function visitors not ported (the converter runs while compiling; Sql.call names a function instead)");
	}

	function testCustomVisitor_WorksViaGlobalFallback_WithoutConfiguration() {
		Assert.skip("IFunctionVisitor: runtime function visitors not ported (the converter runs while compiling; Sql.call names a function instead)");
	}

	function testUnknownMethod_StillThrows() {
		Assert.skip("IFunctionVisitor: runtime function visitors not ported; an unknown method is a compile error here, which a test cannot catch");
	}
}
