package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `PostgresDomainTests.cs`. `DbDomain<T>` declares a PostgreSQL CREATE DOMAIN, which the port does not have. */
class PostgresDomainTests extends TestCase {
	static inline final Reason = "DbDomain: PostgreSQL domain types not ported";

	function testDomainColumn_ReferencesNamedType() {
		Assert.skip(Reason);
	}

	function testDomain_WithDefaultNotNullAndCheck() {
		Assert.skip(Reason);
	}

	function testDomain_WithRangeCheck() {
		Assert.skip(Reason);
	}

	function testDomain_IsInspectedAsDomainDefinition() {
		Assert.skip(Reason);
	}

	function testDropDomain_RendersDropDomain() {
		Assert.skip(Reason);
	}
}
