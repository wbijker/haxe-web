package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `JsonExpressionTests.cs`. `DbJson<T>`, its JSON expressions and the `SqlType.Json` column type are not in the port. */
class JsonExpressionTests extends TestCase {
	static inline final Reason = "JsonExpression: JSON not ported";

	function testJsonExtract_GeneratesCorrectSql_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testJsonExtractText_GeneratesCorrectSql_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testJsonExtract_GeneratesCorrectSql_MySQL() {
		Assert.skip(Reason);
	}

	function testJsonExtractText_GeneratesCorrectSql_MySQL() {
		Assert.skip(Reason);
	}

	function testJsonExtract_GeneratesCorrectSql_SQLite() {
		Assert.skip(Reason);
	}

	function testJsonExtract_GeneratesCorrectSql_MSSQL() {
		Assert.skip(Reason);
	}

	function testJsonExtractText_GeneratesCorrectSql_MSSQL() {
		Assert.skip(Reason);
	}

	function testJsonExists_GeneratesCorrectSql_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testJsonExists_GeneratesCorrectSql_MySQL() {
		Assert.skip(Reason);
	}

	function testJsonArrayLength_GeneratesCorrectSql_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testJsonArrayLength_GeneratesCorrectSql_MySQL() {
		Assert.skip(Reason);
	}

	function testJsonArrayLength_NoPath_GeneratesCorrectSql_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testJsonSet_GeneratesCorrectSql_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testJsonSet_GeneratesCorrectSql_MySQL() {
		Assert.skip(Reason);
	}

	function testJsonRemove_GeneratesCorrectSql_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testJsonRemove_GeneratesCorrectSql_MySQL() {
		Assert.skip(Reason);
	}

	function testJsonValid_GeneratesCorrectSql_MySQL() {
		Assert.skip(Reason);
	}

	function testJsonValid_GeneratesCorrectSql_SQLite() {
		Assert.skip(Reason);
	}

	function testJsonValid_GeneratesCorrectSql_MSSQL() {
		Assert.skip(Reason);
	}

	function testJsonType_GeneratesCorrectSql_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testJsonType_GeneratesCorrectSql_MySQL() {
		Assert.skip(Reason);
	}

	function testJsonMerge_GeneratesCorrectSql_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testJsonMerge_GeneratesCorrectSql_MySQL() {
		Assert.skip(Reason);
	}

	function testSqlType_IsJson_ForJsonProperty() {
		Assert.skip(Reason + " (no SqlType.Json)");
	}

	function testSqliteSqlDriver_JsonTypeName() {
		Assert.skip(Reason + " (no SqlType.Json)");
	}

	function testMySqlSqlDriver_JsonTypeName() {
		Assert.skip(Reason + " (no SqlType.Json)");
	}

	function testPostgresSqlDriver_JsonTypeName() {
		Assert.skip(Reason + " (no SqlType.Json)");
	}

	function testMssqlSqlDriver_JsonTypeName() {
		Assert.skip(Reason + " (no SqlType.Json)");
	}
}
