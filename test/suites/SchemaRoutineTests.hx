package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `SchemaRoutineTests.cs`. Routines in the schema snapshot and its diff: routines are not in the port. */
class SchemaRoutineTests extends TestCase {
	static inline final Reason = "DbFunction/DbStoredProc (SchemaSnapshot.Routines): routines not ported";

	function testAdded_Routine_Emits_CreateBody() {
		Assert.skip(Reason);
	}

	function testChangedBody_Is_Modified_But_IdenticalBody_Is_Not() {
		Assert.skip(Reason);
	}

	function testRemoved_Routine_Emits_Drop() {
		Assert.skip(Reason);
	}

	function testRoutines_SurviveSerializationRoundTrip() {
		Assert.skip(Reason);
	}
}
