package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `Integration/UpsertTests.cs`. */
class Integration_UpsertTests extends TestCase {
	static final Reason = "needs a database: eval has none (PHP runtime only)";

	function testTheGeneratedKeyIsLeftToTheDatabase() {
		Assert.skip(Reason);
	}

	function testByDefaultTheOfferedRowWins() {
		Assert.skip(Reason);
	}

	function testTheUpdateCanReadBothRows() {
		Assert.skip(Reason);
	}

	function testDoNothingKeepsTheRowThatIsThere() {
		Assert.skip(Reason);
	}

	function testUpdateOnlyNamesTheColumnsToOverwrite() {
		Assert.skip(Reason);
	}
}
