package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `SqlMigrationExecutorTests.cs`: every test here runs DDL against an in-memory SQLite database. */
class SqlMigrationExecutorTests extends TestCase {
	static inline final Reason = "needs a database: eval has none (PHP runtime only)";

	function testExecute_CreateTable_CreatesTable() Assert.skip(Reason);
	function testExecute_DropTable_RemovesTable() Assert.skip(Reason);
	function testExecute_AddColumn_AddsColumn() Assert.skip(Reason);
	function testExecute_RenameTable_RenamesTable() Assert.skip(Reason);
	function testExecute_RenameColumn_RenamesColumn() Assert.skip(Reason);
	function testExecute_CreateIndex_CreatesIndex() Assert.skip(Reason);
	function testExecute_DropIndex_RemovesIndex() Assert.skip(Reason);
	function testExecute_Migration_ExecutesAllOperations() Assert.skip(Reason);
	function testExecute_MigrationFromDiff_AppliesChanges() Assert.skip(Reason);
	function testExecute_MigrationWithMultipleColumnOperations() Assert.skip(Reason);
	function testExecuteInTransaction_Success_CommitsChanges() Assert.skip(Reason);
	function testExecuteInTransaction_Failure_RollsBack() Assert.skip(Reason);
	function testExecute_CompleteWorkflow_CreateAndPopulateAndModify() Assert.skip(Reason);
	function testExecute_MigrationFromDefinitionDiff_FullScenario() Assert.skip(Reason);
}
