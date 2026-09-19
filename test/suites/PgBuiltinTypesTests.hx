package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`PgBuiltinTypesTests.cs`.

	PostgreSQL's money, xml, bit, macaddr8 and geometric column types, with their operators and
	functions, come from a driver extension the port does not have.
**/
class PgBuiltinTypesTests extends TestCase {
	static inline final Reason = "PgMoney/PgBit/PgPoint (PgBuiltinFunctionsExtension): PostgreSQL built-in types not ported";

	// ---- Column-type mapping ----

	function testTypes_MapToNativeSqlNames() {
		Assert.skip(Reason);
	}

	function testExtension_SelfRegisters_ViaModuleInitializer() {
		Assert.skip(Reason);
	}

	// ---- Function / operator translation ----

	function testMoneyOperators_Translate() {
		Assert.skip(Reason);
	}

	function testPointOperators_Translate() {
		Assert.skip(Reason);
	}

	function testBitOperators_Translate() {
		Assert.skip(Reason);
	}

	function testBitFunctions_Translate() {
		Assert.skip(Reason);
	}

	function testGeometricFunctions_Translate() {
		Assert.skip(Reason);
	}

	function testGeometricOperators_Translate() {
		Assert.skip(Reason);
	}

	function testNetworkFunctions_Translate() {
		Assert.skip(Reason);
	}

	function testXmlFunctions_Translate() {
		Assert.skip(Reason);
	}

	// ---- Direct execution is not supported ----

	function testOperators_And_Functions_ExecutedDirectly_Throw() {
		Assert.skip(Reason);
	}
}
