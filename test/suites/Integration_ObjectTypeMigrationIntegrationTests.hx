package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/ObjectTypeMigrationIntegrationTests.cs`. */
class Integration_ObjectTypeMigrationIntegrationTests extends TestCase {
	static final Reason = "ObjectTypeKind.Native: composite types not ported";

	function testAnAttributeAdded_IsAlteredIntoTheTypeAndTheRowsKeepEverythingElse() {
		Assert.skip(Reason);
	}

	function testAnAttributeRemoved_IsAlteredOutOfTheTypeAndTakesOnlyItsOwnDataWithIt() {
		Assert.skip(Reason);
	}

	function testOneAddedAndOneRemoved_AreOneStatement_AndTheDropComesFirst() {
		Assert.skip(Reason);
	}

	function testEveryAlterationCarriesItsOwnCascade() {
		Assert.skip(Reason);
	}

	function testAnAttributeRenamed_IsRenamedRatherThanTradedForANewOne() {
		Assert.skip(Reason);
	}

	function testAnAttributeRenamed_KeepsWhatItHeld() {
		Assert.skip(Reason);
	}

	function testAnAttributeRenamed_IsItsOwnStatement() {
		Assert.skip(Reason);
	}

	function testAnAttributeWithTwoItCouldHaveBecome_IsNotGuessedAt() {
		Assert.skip(Reason);
	}

	function testTheTypeRenamed_IsRenamedRatherThanRemade() {
		Assert.skip(Reason);
	}

	function testTheTypeRenamed_TakesTheColumnsDataWithIt() {
		Assert.skip(Reason);
	}

	function testTheTypeRenamedAndReshapedAtOnce_IsRenamedFirstAndAlteredUnderTheNewName() {
		Assert.skip(Reason);
	}

	function testATypeNoColumnEverUsed_IsNotMistakenForARename() {
		Assert.skip(Reason);
	}

	function testAnAttributeRetyped_WhileAColumnUsesTheType_IsRefusedBeforeAnythingIsSent() {
		Assert.skip(Reason);
	}
}
