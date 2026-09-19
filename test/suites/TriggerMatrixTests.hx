package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `TriggerMatrixTests.cs`. The twelve timing/event/level combinations of a `DbTrigger`, and what its references render as: triggers are not in the port. */
class TriggerMatrixTests extends TestCase {
	static inline final Reason = "DbTrigger: routines/triggers not ported";

	// --- One test per row of the matrix ---

	function testRow01_BeforeInsertRow_SeesTheWritableNewRowOnly() {
		Assert.skip(Reason);
	}

	function testRow02_BeforeInsertStatement_SeesNothingAtAll() {
		Assert.skip(Reason);
	}

	function testRow03_BeforeUpdateRow_SeesBothImagesAndNoTables() {
		Assert.skip(Reason);
	}

	function testRow04_BeforeUpdateStatement_SeesNothingAtAll() {
		Assert.skip(Reason);
	}

	function testRow05_BeforeDeleteRow_SeesTheRowWhileItStillExists() {
		Assert.skip(Reason);
	}

	function testRow06_BeforeDeleteStatement_SeesNothingAtAll() {
		Assert.skip(Reason);
	}

	function testRow07_AfterInsertRow_SeesTheStoredRowAndTheInsertedSet() {
		Assert.skip(Reason);
	}

	function testRow08_AfterInsertStatement_SeesTheInsertedSetOnly() {
		Assert.skip(Reason);
	}

	function testRow09_AfterUpdateRow_IsTheOnlyCombinationWithAllFour() {
		Assert.skip(Reason);
	}

	function testRow10_AfterUpdateStatement_SeesBothSetsAndNoRows() {
		Assert.skip(Reason);
	}

	function testRow11_AfterDeleteRow_SeesTheRemovedRowAndTheDeletedSet() {
		Assert.skip(Reason);
	}

	function testRow12_AfterDeleteStatement_SeesTheDeletedSetOnly() {
		Assert.skip(Reason);
	}

	// --- What the references turn into ---

	function testAWhenOverTwoRows_QualifiesEachColumnWithItsOwnCorrelation() {
		Assert.skip(Reason);
	}

	function testABodyWithoutAWhen_HasNoCondition() {
		Assert.skip(Reason);
	}

	function testARowReadInsideTheBody_RendersAsItsCorrelation_NotAsAValue() {
		Assert.skip(Reason);
	}

	function testATransitionTableIsAQueryOverIt() {
		Assert.skip(Reason);
	}

	function testTheSameReferenceTakenTwice_IsTheSameReference() {
		Assert.skip(Reason);
	}

	function testTheWholeTriggerRendersAsStandardCreateTrigger() {
		Assert.skip(Reason);
	}

	function testTriggersKeepDeclarationOrder_WhichIsFiringOrder() {
		Assert.skip(Reason);
	}

	function testTheTriggerIsCreatedUnderTheNameItWasGiven() {
		Assert.skip(Reason);
	}

	function testAnUnnamedTrigger_IsNamedForItsTableAndEvent() {
		Assert.skip(Reason);
	}

	function testTwoUnnamedTriggersOnOneEvent_SayWhichOneNeedsAName() {
		Assert.skip(Reason);
	}
}
