package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`Integration/RealDatabaseTests.cs`. Every test is a `[SkippableTheory]` run once per provider —
	SQLite, PostgreSQL, MySQL, SQL Server — against a database that was migrated and seeded first.
**/
class Integration_RealDatabaseTests extends TestCase {
	static final Reason = "needs a database: eval has none (PHP runtime only)";

	function testMigration_WasScaffoldedAndRun_AgainstTheDatabase_SQLite() {
		Assert.skip(Reason);
	}

	function testMigration_WasScaffoldedAndRun_AgainstTheDatabase_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testMigration_WasScaffoldedAndRun_AgainstTheDatabase_MySQL() {
		Assert.skip(Reason);
	}

	function testMigration_WasScaffoldedAndRun_AgainstTheDatabase_SqlServer() {
		Assert.skip(Reason);
	}

	function testServerGeneratedKeys_ArePopulated_ByTheDatabase_SQLite() {
		Assert.skip(Reason);
	}

	function testServerGeneratedKeys_ArePopulated_ByTheDatabase_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testServerGeneratedKeys_ArePopulated_ByTheDatabase_MySQL() {
		Assert.skip(Reason);
	}

	function testServerGeneratedKeys_ArePopulated_ByTheDatabase_SqlServer() {
		Assert.skip(Reason);
	}

	function testSeededRows_AreActuallyPersisted_SQLite() {
		Assert.skip(Reason);
	}

	function testSeededRows_AreActuallyPersisted_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testSeededRows_AreActuallyPersisted_MySQL() {
		Assert.skip(Reason);
	}

	function testSeededRows_AreActuallyPersisted_SqlServer() {
		Assert.skip(Reason);
	}

	function testFilter_ByCountry_ReturnsMatchingRows_SQLite() {
		Assert.skip(Reason);
	}

	function testFilter_ByCountry_ReturnsMatchingRows_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testFilter_ByCountry_ReturnsMatchingRows_MySQL() {
		Assert.skip(Reason);
	}

	function testFilter_ByCountry_ReturnsMatchingRows_SqlServer() {
		Assert.skip(Reason);
	}

	function testFilter_ByPrice_ReturnsMatchingRows_SQLite() {
		Assert.skip(Reason);
	}

	function testFilter_ByPrice_ReturnsMatchingRows_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testFilter_ByPrice_ReturnsMatchingRows_MySQL() {
		Assert.skip(Reason);
	}

	function testFilter_ByPrice_ReturnsMatchingRows_SqlServer() {
		Assert.skip(Reason);
	}

	function testJoin_BooksToAuthors_CorrelatesByForeignKey_SQLite() {
		Assert.skip(Reason);
	}

	function testJoin_BooksToAuthors_CorrelatesByForeignKey_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testJoin_BooksToAuthors_CorrelatesByForeignKey_MySQL() {
		Assert.skip(Reason);
	}

	function testJoin_BooksToAuthors_CorrelatesByForeignKey_SqlServer() {
		Assert.skip(Reason);
	}

	function testAggregate_SumSalesQuantity_ForOneBook_SQLite() {
		Assert.skip(Reason);
	}

	function testAggregate_SumSalesQuantity_ForOneBook_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testAggregate_SumSalesQuantity_ForOneBook_MySQL() {
		Assert.skip(Reason);
	}

	function testAggregate_SumSalesQuantity_ForOneBook_SqlServer() {
		Assert.skip(Reason);
	}

	function testUpdate_ThenFetch_ReflectsTheChange_SQLite() {
		Assert.skip(Reason);
	}

	function testUpdate_ThenFetch_ReflectsTheChange_PostgreSQL() {
		Assert.skip(Reason);
	}

	function testUpdate_ThenFetch_ReflectsTheChange_MySQL() {
		Assert.skip(Reason);
	}

	function testUpdate_ThenFetch_ReflectsTheChange_SqlServer() {
		Assert.skip(Reason);
	}
}
