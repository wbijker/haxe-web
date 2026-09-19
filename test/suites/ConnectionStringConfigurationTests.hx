package suites;

import codequery.execution.DatabaseConfiguration;
import codequery.sqldrivers.SqlDriver;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`ConnectionStringConfigurationTests.cs`.

	A configuration takes the provider's own connection string, verbatim. This port has one driver
	over one translator and no `BuildConnectionString`, so what is here is the verbatim half: a
	string handed to the driver reaches it untouched, and reaches a configuration built on it.
**/
class ConnectionStringConfigurationTests extends TestCase {
	function testPostgres_TypedParts_FormatCommonOptions() {
		Assert.skip("PostgresSqlDriver.BuildConnectionString: no PostgreSQL dialect driver in this port");
	}

	function testPostgres_OmittedOptions_LeaveNoTrace() {
		Assert.skip("PostgresSqlDriver.BuildConnectionString: no PostgreSQL dialect driver in this port");
	}

	function testPostgres_RawConnectionString_PassesThroughVerbatim() {
		final raw = "Host=localhost;Database=Marisit;Username=docker;Password=docker;Include Error Detail=true";

		final driver = new SqlDriver(new SqlTranslator(), raw);

		Assert.equals(raw, driver.ConnectionString);
	}

	function testForPostgreSql_RawConnectionString_ReachesTheDriver() {
		final raw = "Host=localhost;Database=Marisit;Username=docker;Password=docker";

		final config = DatabaseConfiguration.Of(new SqlDriver(new SqlTranslator(), raw));

		Assert.equals(raw, Assert.isType(config.Driver, SqlDriver).ConnectionString);
	}

	function testMySql_TypedParts_FormatCommonOptions() {
		Assert.skip("MySqlSqlDriver.BuildConnectionString: no MySQL dialect driver in this port");
	}

	function testSqlServer_WithoutUsername_KeepsIntegratedSecurity() {
		Assert.skip("MssqlSqlDriver.BuildConnectionString: no SQL Server dialect driver in this port");
	}

	function testSqlServer_WithUsername_UsesCredentials() {
		Assert.skip("MssqlSqlDriver.BuildConnectionString: no SQL Server dialect driver in this port");
	}

	function testSqlite_TypedParts_FormatModeAndCache() {
		Assert.skip("SqliteSqlDriver.BuildConnectionString: no SQLite dialect driver in this port");
	}

	function testSqlite_RawConnectionString_PassesThroughVerbatim() {
		final raw = "Data Source=app.db;Mode=ReadWriteCreate;Foreign Keys=true";

		final config = DatabaseConfiguration.Of(new SqlDriver(new SqlTranslator(), raw));

		Assert.equals(raw, Assert.isType(config.Driver, SqlDriver).ConnectionString);
	}
}
