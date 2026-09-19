package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `SqliteFullTextTests.cs`. SQLite FTS5 (the `Fts5Query` grammar, MATCH, bm25 and the virtual-table DDL) is not in the port. */
class SqliteFullTextTests extends TestCase {
	static inline final Reason = "SqliteFullText/Fts5Query: SQLite FTS5 full-text search not ported";

	// ---- Fts5Query grammar ----

	function testGrammar_Leaves() {
		Assert.skip(Reason);
	}

	function testGrammar_Operators() {
		Assert.skip(Reason);
	}

	// ---- MATCH ----

	function testMatch_RendersFts5() {
		Assert.skip(Reason);
	}

	function testMatch_RawString() {
		Assert.skip(Reason);
	}

	function testBm25_WithWeights_Highlight_Snippet() {
		Assert.skip(Reason);
	}

	function testBm25_Rank() {
		Assert.skip(Reason);
	}

	// ---- FTS5 virtual-table DDL ----

	function testCreateAndDropVirtualTable() {
		Assert.skip(Reason);
	}
}
