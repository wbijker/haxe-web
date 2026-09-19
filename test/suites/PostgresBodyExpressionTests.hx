package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `PostgresBodyExpressionTests.cs`. A routine body's rendering: `DbStoredProc`/`DbFunction` are not in the port. */
class PostgresBodyExpressionTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc: routines not ported";

	function testNot_RendersInABody() {
		Assert.skip(Reason);
	}

	function testACapturedValue_RendersInABody() {
		Assert.skip(Reason);
	}

	function testACase_RendersInABody() {
		Assert.skip(Reason);
	}

	function testABodyStillRendersColumnsAndVariablesItsOwnWay() {
		Assert.skip(Reason);
	}
}
