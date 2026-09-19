package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `ProfilerMigrationActionsTests.cs`. The profiler's migration actions, over a running database: nothing of it is in this port. */
class ProfilerMigrationActionsTests extends TestCase {
	static final Reason = "Profiler/Logger/Interceptor: not ported";

	function testItListsThemAndSaysWhetherOneCanBeAdded() {
		Assert.skip(Reason);
	}

	function testItHandsBackTheScriptsOfOneMigration() {
		Assert.skip(Reason);
	}

	function testSavingAScriptWritesTheFileAndNothingElse() {
		Assert.skip(Reason);
	}

	function testExecuteRunsTheStatementsAndRecordsNothing() {
		Assert.skip(Reason);
	}

	function testExecuteReportsWhatWentWrong() {
		Assert.skip(Reason);
	}

	function testRollingBackToOneUndoesOnlyWhatCameAfterIt() {
		Assert.skip(Reason);
	}

	function testDeletingTheNewestUndoesItAndRemovesTheFolder() {
		Assert.skip(Reason);
	}

	function testDeletingAnEarlierOneIsRefused() {
		Assert.skip(Reason);
	}

	function testItWritesAMigrationFromTheSchemaInTheCode() {
		Assert.skip(Reason);
	}

	function testItRebuildsTheScriptsFromOneToTheNewest() {
		Assert.skip(Reason);
	}

	function testMergingFoldsTheRunIntoTheFirstOfIt() {
		Assert.skip(Reason);
	}

	function testItRunsWhatIsPending() {
		Assert.skip(Reason);
	}

	function testANameThatIsNotAMigrationIsRefused() {
		Assert.skip(Reason);
	}
}
