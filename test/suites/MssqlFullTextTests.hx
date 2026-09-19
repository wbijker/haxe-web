package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `MssqlFullTextTests.cs`. SQL Server full-text search, rendered by the SQL Server dialect: neither is in the port. */
class MssqlFullTextTests extends TestCase {
	static inline final Reason = "MssqlSqlDriver/MssqlFullText: no SQL Server dialect in this port";

	// ---- SearchCondition grammar ----

	function testGrammar_Leaves() {
		Assert.skip(Reason);
	}

	function testGrammar_Boolean() {
		Assert.skip(Reason);
	}

	function testGrammar_Proximity_FormsOf_IsAbout() {
		Assert.skip(Reason);
	}

	// ---- CONTAINS query predicate ----

	function testContains_WithSearchCondition_RendersContains() {
		Assert.skip(Reason);
	}

	function testContains_WithComplexCondition() {
		Assert.skip(Reason);
	}

	function testContains_WithRawString() {
		Assert.skip(Reason);
	}

	function testContains_ForLanguage_AppendsLanguageOption() {
		Assert.skip(Reason);
	}

	function testFreeText_RendersFreeTextPredicate() {
		Assert.skip(Reason);
	}

	function testFreetexttable_RankedQuery() {
		Assert.skip(Reason);
	}

	// ---- Setup DDL: catalog + index ----

	function testCreateCatalog_AsDefault() {
		Assert.skip(Reason);
	}

	function testCreateIndex_WithKeyIndexAndStoplist() {
		Assert.skip(Reason);
	}

	function testDrop_CatalogAndIndex() {
		Assert.skip(Reason);
	}

	// ---- CONTAINSTABLE ranked query ----

	function testContainstable_RankedQuery() {
		Assert.skip(Reason);
	}
}
