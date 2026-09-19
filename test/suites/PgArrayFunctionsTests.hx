package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`PgArrayFunctionsTests.cs`.

	`PgArray<T>` and `PgFunctions` are the PostgreSQL array type and its operators, functions and
	subscripting, rendered by a driver extension. The port has no array column type.
**/
class PgArrayFunctionsTests extends TestCase {
	static inline final Reason = "PgArray/PgFunctions: PostgreSQL array type not ported";

	function testExtension_SelfRegisters_ViaModuleInitializer() {
		Assert.skip(Reason);
	}

	function testArray_Constructor_Translates() {
		Assert.skip(Reason);
	}

	// ---- Static PgFunctions forms ----

	function testStatic_Operators_Translate() {
		Assert.skip(Reason);
	}

	function testStatic_QuantifiedComparison_Translates() {
		Assert.skip(Reason);
	}

	function testStatic_Subscripting_Translates() {
		Assert.skip(Reason);
	}

	function testStatic_Functions_Translate() {
		Assert.skip(Reason);
	}

	// ---- PgArray<T> member forms ----

	function testMember_Operators_Translate() {
		Assert.skip(Reason);
	}

	function testMember_Quantified_And_Subscript_Translate() {
		Assert.skip(Reason);
	}

	function testMember_Functions_Translate() {
		Assert.skip(Reason);
	}

	function testMember_Chaining_NestsCorrectly() {
		Assert.skip(Reason);
	}

	// ---- C# operators ----

	function testOperators_Translate() {
		Assert.skip(Reason);
	}

	function testEqualityOperator_IsNullSafe_OutsideQuery() {
		Assert.skip(Reason);
	}

	function testOperators_ExecutedDirectly_Throw() {
		Assert.skip(Reason);
	}

	// ---- Direct execution is not supported ----

	function testMember_ExecutedDirectly_Throws() {
		Assert.skip(Reason);
	}

	function testStatic_ExecutedDirectly_Throws() {
		Assert.skip(Reason);
	}
}
