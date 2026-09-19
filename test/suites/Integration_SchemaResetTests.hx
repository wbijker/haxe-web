package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/SchemaResetTests.cs`. */
class Integration_SchemaResetTests extends TestCase {
	static final Reason = "needs a database: eval has none (PHP runtime only)";

	function testItBuildsTheSchemaWithNoMigrationAnywhere() {
		Assert.skip(Reason);
	}

	function testItCanBeRunAgain() {
		Assert.skip(Reason);
	}

	function testAReferencedTableIsDroppedToo() {
		Assert.skip(Reason);
	}

	function testItTakesTablesItNeverDeclared() {
		Assert.skip(Reason);
	}

	function testItTakesDependantsItNeverDeclared() {
		Assert.skip(Reason);
	}

	function testTruncateEmptiesTheTable() {
		Assert.skip(Reason);
	}

	function testATableSomethingPointsAtIsRefused() {
		Assert.skip(Reason);
	}
}
