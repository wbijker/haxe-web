package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`NinthSourceTests.cs` — past the eighth source, by folding the sources into one row with
	`Reduce` and joining on. A projection here is a statement of its own rather than a fold of the
	statement's sources, and a row cannot be a member of one, so the fold has no counterpart.
**/
class NinthSourceTests extends TestCase {
	static final NoFold = "Reduce to a row of rows: not in this port (a projection is a statement of its own, not a fold of the sources)";

	function testANinthTableJoinsThroughAReducedRow() {
		Assert.skip(NoFold);
	}

	function testAndAgainForATenth() {
		Assert.skip(NoFold);
	}
}
