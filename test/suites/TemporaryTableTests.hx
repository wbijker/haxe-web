package suites;

import codequery.migrations.DatabaseColumnDefinition;
import codequery.migrations.DatabaseTableDefinition;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `TemporaryTableTests.cs` — TEMPORARY and (PostgreSQL) UNLOGGED table modifiers on CREATE TABLE. */
class TemporaryTableTests extends TestCase {
	static function table(temp:Bool = false, unlogged:Bool = false):DatabaseTableDefinition {
		return new DatabaseTableDefinition("scratch", [new DatabaseColumnDefinition("id", SqlInt, false)], null,
			temp, unlogged);
	}

	function testPostgres_TemporaryAndUnlogged() {
		Assert.contains("CREATE TEMPORARY TABLE scratch", new SqlTranslator().ToDdl(CreateTable(table(true))));
		Assert.contains("CREATE UNLOGGED TABLE scratch", new SqlTranslator().ToDdl(CreateTable(table(false, true))));
	}

	function testMySqlAndSqlite_Temporary() {
		Assert.contains("CREATE TEMPORARY TABLE scratch", new codequery.mysql.MySqlSqlTranslator().ToDdl(CreateTable(table(true))));
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port for the second half");
	}

	function testUnlogged_Unsupported_Throws() {
		Assert.throws(() -> new codequery.mysql.MySqlSqlTranslator().ToDdl(CreateTable(table(false, true))));
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port for the second half");
	}

	function testSqlServer_Temporary_Throws() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}
}
