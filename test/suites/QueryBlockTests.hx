package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`QueryBlockTests.cs` — `QueryBlock`, a query written as a block where each source is a variable
	rather than a parameter every later clause has to carry. The block form is not in this port.
**/
class QueryBlockTests extends TestCase {
	function testABlockIsTheFluentQueryWrittenOut() {
		Assert.skip("QueryBlock: block-form queries not ported");
	}

	function testABlockCanBeGivenTheTables() {
		Assert.skip("QueryBlock: block-form queries not ported");
	}

	function testEachHandleIsItsOwnSource() {
		Assert.skip("QueryBlock: block-form queries not ported");
	}

	function testTwoHandlesOfOneEntityAreTwoSources() {
		Assert.skip("QueryBlock: block-form queries not ported");
	}

	function testAJoinCanBeWrittenOutInTheBlock() {
		Assert.skip("QueryBlock: block-form queries not ported");
	}

	function testTheClausesAfterItTakeNothing() {
		Assert.skip("QueryBlock: block-form queries not ported");
	}

	function testALimitIsTheBlocksOwn() {
		Assert.skip("QueryBlock: block-form queries not ported");
	}

	function testAColumnInsideAnExpressionIsStillAColumn() {
		Assert.skip("QueryBlock: block-form queries not ported");
	}

	function testAHandleReadOutsideALambdaIsRefused() {
		Assert.skip("QueryBlock: block-form queries not ported");
	}

	function testABlockReadsFromOneTable() {
		Assert.skip("QueryBlock: block-form queries not ported");
	}

}
