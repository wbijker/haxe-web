package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `CteFetchTests.cs` — every test writes rows and fetches them back through a CTE. */
class CteFetchTests extends TestCase {
	static final NeedsDb = "needs a database: eval has none (PHP runtime only)";

	function testCte_WithWindow_FetchesTopSalePerBook() {
		Assert.skip(NeedsDb);
	}

	function testCompositeGroupKey_Aggregation_Window_Cte_Fetch_TopBookPerAuthor() {
		Assert.skip(NeedsDb);
	}

	function testTwoTableJoinOverCte_Fetch_MapsLeftProjection() {
		Assert.skip(NeedsDb);
	}
}
