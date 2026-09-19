package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `MigrationRevertTests.cs`: reverting the last applied migration, which takes a database to have applied it. */
class MigrationRevertTests extends TestCase {
	function testRevertMigration_UnappliesLastMigration_AndIsRepeatable() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
