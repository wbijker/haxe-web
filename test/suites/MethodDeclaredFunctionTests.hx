package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `MethodDeclaredFunctionTests.cs`. A function declared as a schema method: routines are not in the port. */
class MethodDeclaredFunctionTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testFunction_IsNamedAfterItsMethod_AndTakesThatMethodsSignature() {
		Assert.skip(Reason);
	}

	function testParametersAndReturnType_RenderIntoTheCreateFunction() {
		Assert.skip(Reason);
	}

	function testParametersAreReferencedAsNames_NotAsTheValuesTheMethodWasCalledWith() {
		Assert.skip(Reason);
	}

	function testDeclaredDefaults_RenderInTheHeader() {
		Assert.skip(Reason);
	}

	function testReturnsAreTypedToTheFunction_IncludingInsideAGuardClause() {
		Assert.skip(Reason);
	}

	function testCallSite_CarriesItsArguments_IntoTheInvocation() {
		Assert.skip(Reason);
	}

	function testSchema_RegistersEveryFunctionMethod_AsAFunctionNotAProcedure() {
		Assert.skip(Reason);
	}

	function testTheSnapshot_RecordsTheReturnType() {
		Assert.skip(Reason);
	}

	function testPostgresRenders_TheSameSignature_AsPlPgSql() {
		Assert.skip(Reason);
	}

	function testInvoking_BeforeTheSchemaIsBuilt_ExplainsWhatIsMissing() {
		Assert.skip(Reason);
	}
}
