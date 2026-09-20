package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `SequenceTests.cs` — CREATE / DROP SEQUENCE, in each dialect's spelling. */
class SequenceTests extends TestCase {
	function testPostgres_CreateSequence() {
		Assert.skip("PostgresSqlDriver: dialect spelling of CREATE SEQUENCE");
	}

	function testPostgres_DropSequence_IfExists() {
		Assert.skip("PostgresSqlDriver: dialect spelling of DROP SEQUENCE");
	}

	function testSqlServer_CreateSequence_AsBigint() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testMySqlAndSqlite_Throw() {
		Assert.skip("MySqlSqlDriver/SqliteSqlDriver: no MySQL or SQLite dialect in this port");
	}
}
