package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`InsertReturningTests.cs`: generated keys read back from a SQLite file. Every test inserts and
	fetches, which nothing on the eval target can do.
**/
class InsertReturningTests extends TestCase {
	static final NoDatabase = "needs a database: eval has none (PHP runtime only)";

	function testPopulatePrimaryKey_AssignsGeneratedKeys_AndReturnsAffectedRows() {
		Assert.skip(NoDatabase);
	}

	function testPopulatePrimaryKey_SingleEntry_AssignsKey_AndReturnsAffectedRows() {
		Assert.skip(NoDatabase);
	}

	function testWithoutPopulatePrimaryKey_InsertsExplicitIdAndReturnsCount() {
		Assert.skip(NoDatabase);
	}

	function testClientGeneratedGuidKey_IsFilledInBeforeInsert_NoReadBack() {
		Assert.skip("Guid keys: client-generated sequential GUIDs are not ported; " + NoDatabase);
	}
}
