package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `AsyncQueryTests.cs`. Awaited statements over a running database. */
class AsyncQueryTests extends TestCase {
	static final Reason = "FetchAsync/ExecuteAsync: async execution not ported";

	function testItInsertsAndReads() {
		Assert.skip(Reason);
	}

	function testItReadsOneRow() {
		Assert.skip(Reason);
	}

	function testAJoinedQueryAwaitsToo() {
		Assert.skip(Reason);
	}

	function testItUpdatesAndDeletes() {
		Assert.skip(Reason);
	}

	function testTheKeyComesBack() {
		Assert.skip(Reason);
	}

	function testItObservesCancellation() {
		Assert.skip(Reason);
	}

	function testTheDriverAwaits() {
		Assert.skip(Reason);
	}
}
