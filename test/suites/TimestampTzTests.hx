package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`TimestampTzTests.cs` — `PgDateTimeExtensions.WithTimeZone`, which lives in the PostgreSQL
	assembly: a `timestamptz` typed literal and cast are that dialect's own spelling.
**/
class TimestampTzTests extends TestCase {
	function testALiteral_TakesTheTypedLiteralSpelling() {
		Assert.skip("PgDateTimeExtensions.WithTimeZone: PostgreSQL-specific extension (TIMESTAMPTZ) not in this port");
	}

	function testABoundValue_IsCastInstead() {
		Assert.skip("PgDateTimeExtensions.WithTimeZone: PostgreSQL-specific extension (TIMESTAMPTZ) not in this port");
	}

	function testAColumn_CanBeTyped() {
		Assert.skip("PgDateTimeExtensions.WithTimeZone: PostgreSQL-specific extension (TIMESTAMPTZ) not in this port");
	}

	function testItWorksInAProjection() {
		Assert.skip("PgDateTimeExtensions.WithTimeZone: PostgreSQL-specific extension (TIMESTAMPTZ) not in this port");
	}

	function testCalledDirectly_ItThrows() {
		Assert.skip("PgDateTimeExtensions.WithTimeZone: PostgreSQL-specific extension (TIMESTAMPTZ) not in this port");
	}
}
