package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `JsonArrayTests.cs`. `JsonArray<T>` — a constant batch shredded from a JSON literal — is JSON, which the port does not have. */
class JsonArrayTests extends TestCase {
	static inline final Reason = "JsonArray: JSON not ported";

	// ---- JSON payload ----

	function testPostgres_RendersJsonbToRecordset() {
		Assert.skip(Reason);
	}

	function testSqlServer_RendersOpenJsonWith() {
		Assert.skip(Reason);
	}

	function testMySql_RendersJsonTable() {
		Assert.skip(Reason);
	}

	function testSqlite_RendersJsonEachSubquery() {
		Assert.skip(Reason);
	}

	function testEmpty_RendersEmptyJsonArray() {
		Assert.skip(Reason);
	}

	// ---- End-to-end: INSERT … SELECT from the constant ----

	function testInsert_FromJsonArrayConstant_PersistsRows() {
		Assert.skip(Reason + "; and needs a database: eval has none (PHP runtime only)");
	}
}
