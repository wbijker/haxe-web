package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `CodeQueryExecuteExceptionTests.cs`. What a failed statement says. The port's executor seam (`IDatabaseExecutor`) has no exception type wrapping a provider's failure, and nothing here executes. */
class CodeQueryExecuteExceptionTests extends TestCase {
	static final Reason = "CodeQueryExecuteException: execution errors not ported";

	function testAFailedStatement_CarriesTheSqlAndItsValues() {
		Assert.skip(Reason);
	}

	function testAFailedStatement_KeepsTheProvidersOwnExceptionToItself() {
		Assert.skip(Reason);
	}

	function testAFailedStatement_PointsAtTheLineThatAskedForIt() {
		Assert.skip(Reason);
	}

	function testAFailedQuery_CarriesItsStatementToo() {
		Assert.skip(Reason);
	}

	function testAnAwaitedStatement_FailsTheSameWay() {
		Assert.skip(Reason);
	}

	function testABatch_NamesTheStatementTheDatabaseWasBusyWith() {
		Assert.skip(Reason);
	}

	function testABatchThatFailedBeforeAnyStatement_IsLeftAsItIs() {
		Assert.skip(Reason);
	}

	function testAPerRowInsert_NamesTheRowTheDatabaseWasBusyWith() {
		Assert.skip(Reason);
	}

	function testAFailureThatIsNotTheDatabases_IsLeftAsItIs() {
		Assert.skip(Reason);
	}
}
