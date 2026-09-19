package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `CreateFunctionTests.cs`. `CreateFunctionExpression` rendered per dialect: routines are not in the port. */
class CreateFunctionTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc (CreateFunctionExpression): routines not ported";

	function testPostgres_RendersCreateFunction() {
		Assert.skip(Reason);
	}

	function testPostgres_OrReplace_EmitsOrReplace() {
		Assert.skip(Reason);
	}

	function testSqlServer_RendersCreateFunction_WithAtParametersAndBeginEnd() {
		Assert.skip(Reason);
	}

	function testSqlServer_OrReplace_UsesCreateOrAlter() {
		Assert.skip(Reason);
	}

	function testMySql_RendersCreateFunction_WithDeterministic() {
		Assert.skip(Reason);
	}

	function testSqlite_Throws_NoSqlLevelFunctionDeclaration() {
		Assert.skip(Reason);
	}
}
