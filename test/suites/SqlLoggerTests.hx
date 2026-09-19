package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `SqlLoggerTests.cs`. The SQL logger, wrapping an executor: nothing of it is in this port. */
class SqlLoggerTests extends TestCase {
	static final Reason = "Profiler/Logger/Interceptor: not ported";

	function testEveryStatementIsSeenGoingOutAndComingBack() {
		Assert.skip(Reason);
	}

	function testTheSqlIsTheOneThatRan_ParametersAndAll() {
		Assert.skip(Reason);
	}

	function testTheDurationIsMeasured() {
		Assert.skip(Reason);
	}

	function testInsideATransaction_AStatementIsSeenOnce() {
		Assert.skip(Reason);
	}

	function testWhatCameBackIsCounted() {
		Assert.skip(Reason);
	}

	function testAWriteCountsWhatItChanged() {
		Assert.skip(Reason);
	}

	function testTheCallSiteIsThisTest() {
		Assert.skip(Reason);
	}

	function testTheConfigurationDecidesTheLayout() {
		Assert.skip(Reason);
	}

	function testByDefault_ItArrivesLaidOut() {
		Assert.skip(Reason);
	}

	function testWithNoLogger_NothingIsWrapped() {
		Assert.skip(Reason);
	}
}
