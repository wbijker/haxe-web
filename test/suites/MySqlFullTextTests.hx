package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `MySqlFullTextTests.cs`. MySQL full-text search (MATCH … AGAINST), rendered by the MySQL dialect: neither is in the port. */
class MySqlFullTextTests extends TestCase {
	static inline final Reason = "MySqlSqlDriver/MySqlFullText: no MySQL dialect in this port";

	// ---- BooleanQuery grammar ----

	function testGrammar_Leaves() {
		Assert.skip(Reason);
	}

	function testGrammar_Operators() {
		Assert.skip(Reason);
	}

	function testGrammar_RelevanceModifiers() {
		Assert.skip(Reason);
	}

	// ---- MATCH … AGAINST ----

	function testMatch_BooleanMode() {
		Assert.skip(Reason);
	}

	function testMatch_MultipleColumns() {
		Assert.skip(Reason);
	}

	function testMatchNatural_AndQueryExpansion() {
		Assert.skip(Reason);
	}

	function testScore_UsableInProjection() {
		Assert.skip(Reason);
	}

	// ---- FULLTEXT index DDL ----

	function testCreateAndDropIndex() {
		Assert.skip(Reason);
	}
}
