package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`PostgresFullTextTests.cs`.

	`PostgresFunc` (to_tsvector, to_tsquery, @@, ts_rank …), the `PgTsQuery` grammar and the GIN
	index DDL are PostgreSQL full-text search, which the port does not have.
**/
class PostgresFullTextTests extends TestCase {
	static inline final Reason = "PostgresFunc/PgTsQuery: PostgreSQL full-text search not ported";

	// ---- PgTsQuery grammar ----

	function testGrammar_Leaves() {
		Assert.skip(Reason);
	}

	function testGrammar_Operators() {
		Assert.skip(Reason);
	}

	function testGrammar_Nested() {
		Assert.skip(Reason);
	}

	// ---- Functions ----

	function testToTsVector_WithAndWithoutConfig() {
		Assert.skip(Reason);
	}

	function testToTsQuery_FromGrammar_AndRaw() {
		Assert.skip(Reason);
	}

	function testToTsQuery_Variants() {
		Assert.skip(Reason);
	}

	// ---- Match (@@) ----

	function testMatches_RendersMatchOperator() {
		Assert.skip(Reason);
	}

	function testMatches_WithPlainToTsQuery() {
		Assert.skip(Reason);
	}

	// ---- Ranking / highlighting / manipulation ----

	function testRanking_And_Headline() {
		Assert.skip(Reason);
	}

	function testWeighting_And_Introspection() {
		Assert.skip(Reason);
	}

	function testTsQueryOperators() {
		Assert.skip(Reason);
	}

	// ---- GIN full-text index DDL ----

	function testCreateIndex_RendersGinTsvector() {
		Assert.skip(Reason);
	}

	function testDropIndex_Renders() {
		Assert.skip(Reason);
	}
}
