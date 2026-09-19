package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/IdentityAndDefaultMigrationTests.cs`. */
class Integration_IdentityAndDefaultMigrationTests extends TestCase {
	static final Reason = "needs a database: eval has none (PHP runtime only)";

	function testMigratingToGeneratedAlways_ChangesWhatTheServerSaysTheColumnIs() {
		Assert.skip(Reason);
	}

	function testAfterTheMigration_TheInsertKnowsToSayOverridingSystemValue() {
		Assert.skip(Reason);
	}

	function testMigratingBack_ReturnsTheColumnToTheOrdinaryForm() {
		Assert.skip(Reason);
	}

	function testTheDefaultThePropertyStates_IsTheDefaultTheTableHas() {
		Assert.skip(Reason);
	}

	function testChangingTheInitializer_MigratesTheDefault_AndTheNextRowGetsTheNewOne() {
		Assert.skip(Reason);
	}

	function testNothingChanged_MeansNoMigration_EvenThoughTheDefaultCameFromCode() {
		Assert.skip(Reason);
	}
}
