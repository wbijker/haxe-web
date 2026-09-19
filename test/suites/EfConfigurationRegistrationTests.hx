package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `EfConfigurationRegistrationTests.cs`. */
class EfConfigurationRegistrationTests extends TestCase {
	static final Reason = "EntityFramework: not ported";

	function testWithoutUseCodeQuery_TheErrorSaysWhatToCall() {
		Assert.skip(Reason);
	}

	function testTheRegisteredTranslator_IsWhatTheDriverRendersWith() {
		Assert.skip(Reason);
	}

	function testTheDriver_ExecutesOnTheContext_NotOnAConnectionOfItsOwn() {
		Assert.skip(Reason);
	}

	function testTheConfiguration_IsBuiltOncePerContext() {
		Assert.skip(Reason);
	}

	function testEachContext_GetsItsOwnDriver_EvenFromTheSameOptions() {
		Assert.skip(Reason);
	}

	function testADialectWithoutResultSetKeys_GetsTheLastInsertIdExecutor() {
		Assert.skip(Reason);
	}

	function testUseCodeQuery_ReturnsTheBuilderSoItChains() {
		Assert.skip(Reason);
	}

	function testUseCodeQuery_RejectsANullTranslator() {
		Assert.skip(Reason);
	}
}
