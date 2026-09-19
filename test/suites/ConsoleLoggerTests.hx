package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `ConsoleLoggerTests.cs`. The console logger: nothing of it is in this port. */
class ConsoleLoggerTests extends TestCase {
	static final Reason = "Profiler/Logger/Interceptor: not ported";

	function testTheStatementIsWrittenWithItsValuesInIt() {
		Assert.skip(Reason);
	}

	function testThePlaceholdersCanBeKept() {
		Assert.skip(Reason);
	}

	function testTheDurationIsWrittenAfter() {
		Assert.skip(Reason);
	}

	function testWhatCameBackIsCounted() {
		Assert.skip(Reason);
	}

	function testTheCallSiteIsATerminalHyperlinkToTheFile() {
		Assert.skip(Reason);
	}

	function testWithNoCallSite_NothingIsSaidAboutOne() {
		Assert.skip(Reason);
	}

	function testALongerPlaceholderIsReplacedFirst() {
		Assert.skip(Reason);
	}

	function testTheCallSiteIsALineOfItsOwn() {
		Assert.skip(Reason);
	}

	function testWithNoMethodName_TheLineIsStillThere() {
		Assert.skip(Reason);
	}

	function testEveryStatementIsFollowedByABlankLine() {
		Assert.skip(Reason);
	}

	function testAnAsyncMethodIsNamedAsItWasWritten() {
		Assert.skip(Reason);
	}

	function testALambdaIsNamedForTheMethodItIsIn() {
		Assert.skip(Reason);
	}
}
