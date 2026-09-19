package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`SubqueryPruningTests.cs` — a joined subquery says only the columns the outer query names. C#
	names every column a query selects (`SelectionExpander`) and prunes the list; this port selects
	`*`, so there is no column list to prune and nothing here can be shown.
**/
class SubqueryPruningTests extends TestCase {
	static final NoColumns = "SelectionExpander: this port selects * rather than naming every column, so there is nothing to prune";

	function testOnlyTheColumnsTheOuterQueryNames() {
		Assert.skip(NoColumns);
	}

	function testTheJoinKeyCounts() {
		Assert.skip(NoColumns);
	}

	function testASingleColumnKeepsItsName() {
		Assert.skip(NoColumns);
	}

	function testAWrittenProjectionIsUntouched() {
		Assert.skip(NoColumns);
	}

	function testADistinctSubqueryIsUntouched() {
		Assert.skip(NoColumns);
	}

	function testAnOuterSelectStarIsUntouched() {
		Assert.skip(NoColumns);
	}
}
