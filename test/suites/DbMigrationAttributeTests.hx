package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`DbMigrationAttributeTests.cs`: how a changed function, procedure, trigger or view is put into the
	database, and who runs the statement that does it. None of the four kinds of object are in this port.
**/
class DbMigrationAttributeTests extends TestCase {
	static inline final Routines = "DbFunction/DbStoredProc: routines not ported";
	static inline final Views = "DbView migration strategies: routines not ported";
	static inline final Triggers = "Trigger: routines not ported";

	function testByDefault_TheRoutineIsReplacedInPlace() Assert.skip(Routines);
	function testDropThenCreate_DropsFirst() Assert.skip(Routines);
	function testDropCascadeThenCreate_TakesItsDependantsWithIt() Assert.skip(Routines);
	function testATrigger_IsDroppedWithItsTableAndTheFunctionHoldingItsBody() Assert.skip(Triggers);
	function testAView_IsNotBuiltHere() Assert.skip(Views);
	function testTheViewOnlyStrategies_AreRefusedForARoutine_DropCascadeThenRestore() Assert.skip(Routines);
	function testTheViewOnlyStrategies_AreRefusedForARoutine_CreateIfAbsent() Assert.skip(Routines);
	function testTheViewOnlyStrategies_AreRefusedForARoutine_RenameSwap() Assert.skip(Routines);
	function testEveryDialect_DropsInItsOwnSpelling() Assert.skip(Routines);
	function testABodyThatSaysNothing_IsRunByTheApplicationAndNotByAMigration() Assert.skip(Routines);
	function testABodyThatSaysNothing_IsStillReplacedInPlace() Assert.skip(Routines);
	function testNoMigrationCarriesABodyThatSaysNothing() Assert.skip(Routines);
	function testAskingForAMigration_IsWhatPutsABodyInOne() Assert.skip(Routines);
	function testABodyHandedToTheApplication_IsNeitherDroppedNorCreated() Assert.skip(Routines);
	function testTheStrategy_IsPartOfTheRecordedCreate() Assert.skip(Routines);
	function testARoutineNoMigrationCarries_IsStillInTheSchema_AndSaysSo() Assert.skip(Routines);
	function testTheStrategy_AndWhoRunsIt_AreIndependent() Assert.skip(Routines);
	function testAProcedure_SaysItTheSameWay() Assert.skip(Routines);
	function testNoMigrationCreatesAnInlineRoutine() Assert.skip(Routines);
	function testAnInlineRoutineTheSchemaDrops_IsDroppedByTheMigration() Assert.skip(Routines);
	function testARoutineHandedBackToTheMigrations_IsCreatedByTheNextOne() Assert.skip(Routines);
	function testATrigger_SaysItsStrategyOnTheBuilder() Assert.skip(Triggers);
	function testAView_TakesTheSameAttribute() Assert.skip(Views);
	function testNoMigrationCreatesAViewTheSchemaKeepsToItself() Assert.skip(Views);
	function testRewritingAnInlineBody_IsNotASchemaChange() Assert.skip(Routines);
	function testRewritingAMigratedBody_StillIs() Assert.skip(Routines);
	function testWhetherAMigrationCarriesIt_SurvivesTheSnapshotFile() Assert.skip(Routines);
	function testAnUnchangedSchema_WritesNoSecondMigration() Assert.skip(Routines);
	function testTheDownScript_DoesNotRestoreWhatNoMigrationCarried() Assert.skip(Routines);
	function testTheUpScript_NamesWhatItIsNotCarrying() Assert.skip(Routines);
}
