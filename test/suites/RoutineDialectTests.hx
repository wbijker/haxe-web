package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `RoutineDialectTests.cs`. Procedures, functions and trigger bodies rendered per dialect: routines are not in the port. */
class RoutineDialectTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testProcedure_OnAPostgresSchema_RendersPlPgSql() {
		Assert.skip(Reason);
	}

	function testFunction_OnAPostgresSchema_RendersPlPgSql() {
		Assert.skip(Reason);
	}

	function testProcedure_OnAnMssqlSchema_RendersTSql() {
		Assert.skip(Reason);
	}

	function testProcedure_OnAMySqlSchema_RendersMySqlsProceduralSpelling() {
		Assert.skip(Reason);
	}

	function testFunction_OnAMySqlSchema_IsDeterministicAndReturnsItsType() {
		Assert.skip(Reason);
	}

	function testProcedure_OnAnMssqlSchema_IsInvokedWithExec() {
		Assert.skip(Reason);
	}

	function testProcedure_OnAPostgresSchema_IsInvokedWithCall() {
		Assert.skip(Reason);
	}

	function testValueReturningProcedure_OnAPostgresSchema_PassesNullForTheResultParameter() {
		Assert.skip(Reason);
	}

	function testValueReturningProcedure_OnAnMssqlSchema_CapturesTheReturnStatus() {
		Assert.skip(Reason);
	}

	function testComment_OnAPostgresSchema_RendersInsideTheBody() {
		Assert.skip(Reason);
	}

	function testProcedure_OnASqliteSchema_IsRefused() {
		Assert.skip(Reason);
	}

	function testTriggerBody_OnSqlite_TakesOnlyDataStatements() {
		Assert.skip("DbTrigger: routines/triggers not ported");
	}

	function testAReservedParameterName_IsQuotedForTheDialectsThatNameVariablesBare() {
		Assert.skip(Reason);
	}

	function testAnOptionalParameter_IsRefusedByMySql() {
		Assert.skip(Reason);
	}

	function testACast_RendersInEveryDialectsRoutineBody() {
		Assert.skip(Reason);
	}

	function testLoopsAreLabelled_SoMySqlsLeaveAndIterateHaveSomethingToName() {
		Assert.skip(Reason);
	}

	function testLocalsAreHoisted_ToWhereMySqlWillAcceptTheirDeclaration() {
		Assert.skip(Reason);
	}

	function testLoopsAreNotLabelled_WhereTheDialectDoesNotNeedIt() {
		Assert.skip(Reason);
	}

	function testAValueReturningProcedure_HandsItsResultBack_ThroughTheDialectsOwnMeans() {
		Assert.skip(Reason);
	}

	function testProcedure_OnAnUnboundSchema_StillRenders() {
		Assert.skip(Reason);
	}

	function testTriggerBody_TakesTheDialectItIsGiven() {
		Assert.skip("DbTrigger: routines/triggers not ported");
	}
}
