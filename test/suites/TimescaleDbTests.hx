package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/** `TimescaleDbTests.HourlyReading` — the rows of the continuous aggregate. */
class HourlyReading {
	public var bucket:codequery.SqlDate;
	public var deviceId:Int = 0;
	public var average:Float = 0;

	public function new() {}
}

/**
	`TimescaleDbTests.cs`.

	TimescaleDB is a PostgreSQL extension: hypertables, policies, continuous aggregates and the
	hyperfunctions are all outside the port. The one thing generic in the file — that a member
	declared over the aggregate is queried like a table — is ported as a query over the table it
	would have named.
**/
class TimescaleDbTests extends TestCase {
	static inline final Reason = "TimescaleDb: PostgreSQL extension";

	function testUseTimescaleDb_InstallsTheExtension() {
		Assert.skip(Reason);
	}

	function testAsHypertable_CreatesTheHypertableFromTheTimeColumn() {
		Assert.skip(Reason);
	}

	function testAddSpaceDimension_PartitionsByAHashOfTheColumn() {
		Assert.skip(Reason);
	}

	function testEnableColumnstore_SetsSegmentByAndOrderBy() {
		Assert.skip(Reason);
	}

	function testPolicies_AreAddedWithTheirRemoval() {
		Assert.skip(Reason);
	}

	function testStatements_KeepTheOrderTheyWereDeclaredIn() {
		Assert.skip(Reason);
	}

	function testContinuousAggregate_IsCreatedFromItsDefinition() {
		Assert.skip(Reason);
	}

	function testContinuousAggregate_Policies_UseItsName() {
		Assert.skip(Reason);
	}

	/** The `DbContinuousAggregate` member is out of scope; the query it answers with is a plain one. */
	function testContinuousAggregateMember_IsQueryable_AndSelectsFromTheAggregate() {
		final select = Query.select(HourlyReading, "readings_hourly").Where(h -> h.deviceId == 1).ToExpression();

		Assert.equals("readings_hourly", select.selectTableName());
		select.whereClause().comparison("deviceId", Equal, 1);
	}

	function testMigration_AppliesTheStatements_AfterTheTable_AndUndoesThemOnTheWayDown() {
		Assert.skip(Reason);
	}

	function testUnchangedSchema_DiffsClean() {
		Assert.skip(Reason);
	}

	function testChangedPolicy_IsRemovedThenAddedAgain() {
		Assert.skip(Reason);
	}

	// --- Hyperfunctions in queries ---

	function testTimeBucket_TranslatesToTheHyperfunction() {
		Assert.skip(Reason);
	}

	function testGapfill_Locf_And_Interpolate_Translate() {
		Assert.skip(Reason);
	}

	function testFirstAndLast_Translate() {
		Assert.skip(Reason);
	}

	function testToolkit_AggregatesAndAccessors_Translate() {
		Assert.skip(Reason);
	}

	function testIrregularNames_KeepTheirSqlSpelling() {
		Assert.skip(Reason);
	}

	// --- SQL rendering the whole package is built on ---

	function testInterval_RendersInItsLargestWholeUnit_7Days() {
		Assert.skip(Reason);
	}

	function testInterval_RendersInItsLargestWholeUnit_6Hours() {
		Assert.skip(Reason);
	}

	function testInterval_RendersInItsLargestWholeUnit_1Hour() {
		Assert.skip(Reason);
	}

	function testInterval_RendersInItsLargestWholeUnit_90Minutes() {
		Assert.skip(Reason);
	}

	function testInterval_RendersInItsLargestWholeUnit_36Hours() {
		Assert.skip(Reason);
	}

	function testRegclass_QuotesTheTable_SoCapitalsSurvive() {
		Assert.skip(Reason);
	}

	function testHyperfunctions_AreTranslationOnly() {
		Assert.skip(Reason);
	}

	function testUseTimescaleDb_RequiresPostgres() {
		Assert.skip(Reason);
	}
}
