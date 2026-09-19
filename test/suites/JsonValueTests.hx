package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `JsonValueTests.cs`. The `DbJson` operator and function surface, per dialect: JSON is not in the port. */
class JsonValueTests extends TestCase {
	static inline final Reason = "JsonExpression: JSON not ported";

	// ---- PostgreSQL: full operator surface ----

	function testPostgres_Operators() {
		Assert.skip(Reason);
	}

	function testPostgres_Functions() {
		Assert.skip(Reason);
	}

	function testPostgres_ArrayFunctions() {
		Assert.skip(Reason);
	}

	function testMySql_And_Sqlite_ArrayAppend() {
		Assert.skip(Reason);
	}

	function testPostgres_MemberOf_Throws() {
		Assert.skip(Reason);
	}

	// ---- MySQL ----

	function testMySql_Operators_And_Functions() {
		Assert.skip(Reason);
	}

	function testMySql_PostgresOnlyOperators_Throw() {
		Assert.skip(Reason);
	}

	// ---- SQLite ----

	function testSqlite_Operators_And_Functions() {
		Assert.skip(Reason);
	}

	function testSqlite_ContainmentOperators_Throw() {
		Assert.skip(Reason);
	}

	// ---- SQL Server ----

	function testSqlServer_ExtractionViaFunctions() {
		Assert.skip(Reason);
	}

	function testSqlServer_StructuralOperators_Throw() {
		Assert.skip(Reason);
	}

	// ---- JSON → rows (lateral join) ----

	function testArrayElements_Postgres_RendersJsonbArrayElementsLateral() {
		Assert.skip(Reason);
	}

	function testArrayElements_MySql_RendersJsonTable() {
		Assert.skip(Reason);
	}

	function testArrayElements_SqlServer_RendersOpenJsonOuterApply() {
		Assert.skip(Reason);
	}

	function testEach_Postgres_RendersJsonbEach() {
		Assert.skip(Reason);
	}

	function testArrayElements_Sqlite_LateralUnsupported_Throws() {
		Assert.skip(Reason);
	}

	// ---- Direct execution is not supported ----

	function testMembers_ExecutedDirectly_Throw() {
		Assert.skip(Reason);
	}
}
