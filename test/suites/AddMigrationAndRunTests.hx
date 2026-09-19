package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `AddMigrationAndRunTests.cs`: written and applied in one call — every test applies against SQLite. */
class AddMigrationAndRunTests extends TestCase {
	static inline final Reason = "needs a database: eval has none (PHP runtime only)";

	function testWrittenAndRun_InOneCall() Assert.skip(Reason);
	function testItRunsTheFolderItWroteTo_WhichIsNotTheOneApplyModeReads() Assert.skip(Reason);
	function testWithoutTheFlag_TheMigrationIsWrittenAndNotRun() Assert.skip(Reason);
	function testNothingScaffolded_StillAppliesWhatIsOutstanding() Assert.skip(Reason);
	function testRunTwice_AppliesOnce() Assert.skip(Reason);
}
