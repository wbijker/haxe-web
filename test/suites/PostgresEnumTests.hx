package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `PostgresEnumTests.cs`. `[DatabaseEnum]` declares a PostgreSQL CREATE TYPE … AS ENUM, which the port does not have. */
class PostgresEnumTests extends TestCase {
	static inline final Reason = "DatabaseEnum: PostgreSQL native enum types not ported";

	function testEnumColumn_ReferencesNamedType() {
		Assert.skip(Reason);
	}

	function testNativeEnum_EmitsCreateTypeAsEnum() {
		Assert.skip(Reason);
	}

	function testNativeEnum_DedupedAcrossProperties() {
		Assert.skip(Reason);
	}
}
