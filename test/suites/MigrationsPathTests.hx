package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`MigrationsPathTests.cs` and `MigrationScaffoldPathTests` in the same file: where `WithMigrations`
	settles the folder — against the assembly's directory, or a scaffold path. This port's store is
	handed a folder and nothing else.
**/
class MigrationsPathTests extends TestCase {
	static inline final Reason = "DatabaseConfiguration.WithMigrations/MigrationModes: migration path configuration not ported";

	function testARelativePathIsTakenFromTheAssemblyDirectory() Assert.skip(Reason);
	function testAnAbsolutePathIsUsedAsItIs() Assert.skip(Reason);
	function testTheWorkingDirectoryDoesNotDecideIt() Assert.skip(Reason);
	function testItDoesNotMoveOnceSettled() Assert.skip(Reason);
	function testTheFolderNameDefaults() Assert.skip(Reason);
	function testThereIsNoSourcePathUntilOneIsGiven() Assert.skip(Reason);
	function testScaffoldingWritesTheFolderUnderTheScaffoldPath() Assert.skip(Reason);
	function testBothModesUseTheSameFolderName() Assert.skip(Reason);
	function testApplyModeIsUnaffectedByTheScaffoldPath() Assert.skip(Reason);
	function testWithoutAScaffoldPathItFallsBackToApply() Assert.skip(Reason);
}
