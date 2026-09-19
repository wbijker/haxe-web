package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `ProfilerTests.cs`. The profiler's page, socket and feed: nothing of it is in this port. */
class ProfilerTests extends TestCase {
	static final Reason = "Profiler/Logger/Interceptor: not ported";

	function testItServesItsOwnPage() {
		Assert.skip(Reason);
	}

	function testItServesTheScriptThatDocksItIntoAnotherPage() {
		Assert.skip(Reason);
	}

	function testThePageCanCloseItselfWhenItIsDocked() {
		Assert.skip(Reason);
	}

	function testTheFeedsControlsAreInTheBar_NotAboveTheFeed() {
		Assert.skip(Reason);
	}

	function testTheOldestRowIsDroppedByArrival_NotByWhereItSitsOnTheScreen() {
		Assert.skip(Reason);
	}

	function testThePageColoursTheSqlItself() {
		Assert.skip(Reason);
	}

	function testThePageIsInTwoTabs_AndOpensOnTheQueries() {
		Assert.skip(Reason);
	}

	function testTheMigrationsAreThere_AndSayWhatTheDatabaseHasRun() {
		Assert.skip(Reason);
	}

	function testThePageIsCarriedInTheAssembly() {
		Assert.skip(Reason);
	}

	function testEveryQueryReachesTheSocket_TwiceOver() {
		Assert.skip(Reason);
	}

	function testAPageOpenedLate_IsShownWhatItMissed() {
		Assert.skip(Reason);
	}

	function testItSaysWhereTheQueryWasAskedFor() {
		Assert.skip(Reason);
	}

	function testItCarriesTheWholePathAndTheLine() {
		Assert.skip(Reason);
	}

	function testTheCallSiteIsALink_RiderUnlessToldOtherwise() {
		Assert.skip(Reason);
	}

	function testTheTemplateIsTheApplicationsToChoose() {
		Assert.skip(Reason);
	}

	function testNoTemplate_NoLink() {
		Assert.skip(Reason);
	}

	function testReadingTheMigrations_DoesNotShowUpAsQueries() {
		Assert.skip(Reason);
	}

	function testAQueryIsOneRow_NotTwo() {
		Assert.skip(Reason);
	}

	function testAQueryInsideATransactionIsAlsoOneRow() {
		Assert.skip(Reason);
	}

	function testASynchronousQueryIsAlsoOneRow() {
		Assert.skip(Reason);
	}

	function testClearingTheQueries_AlsoForgetsTheBacklog() {
		Assert.skip(Reason);
	}

	function testOnlyADelete_Clears() {
		Assert.skip(Reason);
	}

	function testALoggerAlreadyThere_IsKept() {
		Assert.skip(Reason);
	}

	function testALoggerRegisteredAfterTheProfiler_IsKeptAndSoIsTheProfiler() {
		Assert.skip(Reason);
	}

	function testALoggerOnEachSideOfTheProfiler_AreBothKept() {
		Assert.skip(Reason);
	}
}
