package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`PgDoTests.cs`.

	`PgDo` is a PostgreSQL `DO $$ … $$` block written in the routine DSL — declarations, guards,
	loops, RAISE and GRANT — and registered on the schema as a statement. Neither the DSL nor the
	schema statements are in the port.
**/
class PgDoTests extends TestCase {
	static inline final Reason = "PgDo: PostgreSQL DO block (routine DSL) not ported";

	// ---- the block itself ----

	function testItIsADoBlock() {
		Assert.skip(Reason);
	}

	function testAConstant_IsDeclaredWithItsValue() {
		Assert.skip(Reason);
	}

	function testAQueryLoopVariable_IsDeclared() {
		Assert.skip(Reason);
	}

	function testTheGuard_ReadsTheCatalogue() {
		Assert.skip(Reason);
	}

	function testARaise_CarriesItsArguments() {
		Assert.skip(Reason);
	}

	function testTheLoop_IsOverTheQuery_InItsOrder() {
		Assert.skip(Reason);
	}

	function testAGrantOnAVariableTable_IsBuiltAsItRuns() {
		Assert.skip(Reason);
	}

	function testTheWholeBlock() {
		Assert.skip(Reason);
	}

	// ---- GRANT ----

	function testAGrantOnAKnownTable_IsWrittenOut() {
		Assert.skip(Reason);
	}

	function testEveryPrivilege_IsAllPrivileges() {
		Assert.skip(Reason);
	}

	// ---- the schema ----

	function testTheSchemaRegistersItAsAStatement() {
		Assert.skip(Reason);
	}

	function testItIsAppliedAfterTheRoutines() {
		Assert.skip(Reason);
	}

	function testOnlyAChangedBlockIsReApplied() {
		Assert.skip(Reason);
	}

	// ---- RAISE ----

	function testAMessageWhosePlaceholdersDoNotMatchItsArguments_IsRefused() {
		Assert.skip(Reason);
	}

	function testAnEscapedPercent_IsNotAPlaceholder() {
		Assert.skip(Reason);
	}
}
