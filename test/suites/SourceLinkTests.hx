package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `SourceLinkTests.cs`. `SourceLink` is the profiler's, and the profiler is not here. The `[Theory]` has two rows, null and empty. */
class SourceLinkTests extends TestCase {
	static final Reason = "Profiler/Logger/Interceptor: not ported";

	function testItWritesTheFileAndTheLineIntoTheTemplate() {
		Assert.skip(Reason);
	}

	function testASlashAndAColonSurviveIntact() {
		Assert.skip(Reason);
	}

	function testWhatWouldBreakTheUrl_TravelsEncoded() {
		Assert.skip(Reason);
	}

	function testTheMemberIsAvailableToATemplateThatWantsIt() {
		Assert.skip(Reason);
	}

	function testANameThatIsNotAscii_GoesAsUtf8() {
		Assert.skip(Reason);
	}

	function testNoTemplate_NoLink_Null() {
		Assert.skip(Reason);
	}

	function testNoTemplate_NoLink_Empty() {
		Assert.skip(Reason);
	}

	function testNoCallSite_NoLink() {
		Assert.skip(Reason);
	}
}
