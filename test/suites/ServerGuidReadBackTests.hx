package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `ServerGuidReadBackTests.cs` — server-generated Guid keys read back after an insert. */
class ServerGuidReadBackTests extends TestCase {
	function testSqlite_ServerGeneratedGuid_IsGeneratedByDbAndReadBack() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testMySql_ServerGeneratedGuid_WithPopulate_FailsClearly() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}
}
