package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `TriggerMigrationTests.cs`. A trigger declared on a table, snapshotted and migrated: triggers are not in the port. */
class TriggerMigrationTests extends TestCase {
	static inline final Reason = "DbTrigger: routines/triggers not ported";

	function testADbSchemaDeclaresTriggersTheSameWayAnIDbSchemaDoes() {
		Assert.skip(Reason);
	}

	function testADeclaredTrigger_IsInTheSnapshot_AsARoutineOnItsTable() {
		Assert.skip(Reason);
	}

	function testANewTrigger_IsCreated_ByTheDiff() {
		Assert.skip(Reason);
	}

	function testARemovedTrigger_IsDropped_ByTheDiff() {
		Assert.skip(Reason);
	}

	function testDroppingATrigger_NamesItsTable_OnPostgres() {
		Assert.skip(Reason);
	}

	function testAPostgresTrigger_IsAFunction_AndATriggerThatExecutesIt() {
		Assert.skip(Reason);
	}

	function testAStandardTrigger_KeepsItsBody_AndItsCorrelationNames() {
		Assert.skip(Reason);
	}
}
