package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DateTimeOffsetTypeTests.cs` — DateTimeOffset as a column type, with a dialect type each. */
class DateTimeOffsetTypeTests extends TestCase {
	function testConverter_MapsDateTimeOffsetColumn() {
		Assert.skip("DateTimeOffset: no zoned date type in this port (Haxe has only Date)");
	}

	function testDdl_RendersDialectType_postgres() {
		Assert.skip("DateTimeOffset: no zoned date type in this port; CreateTableExpression with a TIMESTAMPTZ column is PostgreSQL's spelling");
	}

	function testDdl_RendersDialectType_mssql() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testDdl_RendersDialectType_mysql() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testDdl_RendersDialectType_sqlite() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}
}
