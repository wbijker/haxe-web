package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `MethodDeclaredProcTests.cs`. A procedure declared as a schema method: routines are not in the port. */
class MethodDeclaredProcTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testProcedure_IsNamedAfterItsMethod_AndTakesThatMethodsSignature() {
		Assert.skip(Reason);
	}

	function testParametersRenderIntoTheHeader_WithTheirDeclaredDefaults() {
		Assert.skip(Reason);
	}

	function testParametersAreReferencedAsNames_NotAsTheValuesTheMethodWasCalledWith() {
		Assert.skip(Reason);
	}

	function testGenericProcedure_TypesItsReturns_IncludingInsideAGuardClause() {
		Assert.skip(Reason);
	}

	function testUnusedParameter_StaysInTheSignature_AndTakesItsArgumentOnTheCall() {
		Assert.skip(Reason);
	}

	function testCallSite_CarriesItsArguments_IntoTheExecStatement() {
		Assert.skip(Reason);
	}

	function testSchema_RegistersEveryProcedureMethod() {
		Assert.skip(Reason);
	}

	function testPostgresRenders_TheSameSignature_WithPlPgSqlDefaults() {
		Assert.skip(Reason);
	}

	function testExecuting_BeforeTheSchemaIsBuilt_ExplainsWhatIsMissing() {
		Assert.skip(Reason);
	}

	function testOverloadedProcedureMethods_AreRejected_RatherThanGuessed() {
		Assert.skip(Reason);
	}
}
