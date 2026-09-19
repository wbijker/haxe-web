package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`AtTimeZoneTests.cs` — PostgreSQL's `AT TIME ZONE`, reached through `PgDateTimeExtensions.AtTimeZone`:
	a dialect-specific operator, so both the node and the translation live in the Postgres assembly.
**/
class AtTimeZoneTests extends TestCase {
	function testAtTimeZone_RendersTheOperator() {
		Assert.skip("PgDateTimeExtensions.AtTimeZone: PostgreSQL-specific extension not in this port");
	}

	function testAtTimeZone_WorksInAPredicate() {
		Assert.skip("PgDateTimeExtensions.AtTimeZone: PostgreSQL-specific extension not in this port");
	}

	function testAtTimeZone_TakesTheZoneFromAVariable() {
		Assert.skip("PgDateTimeExtensions.AtTimeZone: PostgreSQL-specific extension not in this port");
	}

	function testAtTimeZone_CalledDirectly_Throws() {
		Assert.skip("PgDateTimeExtensions.AtTimeZone: PostgreSQL-specific extension not in this port");
	}

	function testAtTimeZone_RendersInsideARoutineBody() {
		Assert.skip("PgDateTimeExtensions.AtTimeZone: PostgreSQL-specific extension not in this port; DbFunction/DbStoredProc: routines not ported");
	}
}
