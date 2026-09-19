package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `EfDbSetToCodeQueryTests.cs`. */
class EfDbSetToCodeQueryTests extends TestCase {
	static final Reason = "EntityFramework: not ported";

	function testToCodeQuery_ReturnsATableOverEfsTableName() {
		Assert.skip(Reason);
	}

	function testToCodeQuery_BindsTheRegisteredConfiguration() {
		Assert.skip(Reason);
	}

	function testFrom_Where_ReadsTheMappedTable() {
		Assert.skip(Reason);
	}

	function testFrom_Select_ProjectsByPropertyName() {
		Assert.skip(Reason);
	}

	function testToCodeQuery_OnTheContext_MatchesTheDbSet() {
		Assert.skip(Reason);
	}

	function testCodeQuerySource_OnTheDbSet_ReportsTheSameMapping() {
		Assert.skip(Reason);
	}

	function testFetch_ReadsTheRowsEfWrote() {
		Assert.skip(Reason);
	}

	function testInsert_IsVisibleToEf() {
		Assert.skip(Reason);
	}
}
