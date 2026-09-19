package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `EfDriverExecutionTests.cs`. */
class EfDriverExecutionTests extends TestCase {
	static final Reason = "EntityFramework: not ported";

	function testTheDriverRendersExactlyWhatTheNativeDriverRenders() {
		Assert.skip(Reason);
	}

	function testTheDriverTakesWhicheverDialectItIsGiven() {
		Assert.skip(Reason);
	}

	function testNoEfDriver_ClaimsBinaryCopy_ItHasNoConnectionOfItsOwn() {
		Assert.skip(Reason);
	}

	function testInsertAndRead_GoThroughTheContextsConnection() {
		Assert.skip(Reason);
	}

	function testWritesJoinTheContextsTransaction_AndRollBackWithIt() {
		Assert.skip(Reason);
	}

	function testGeneratedKeys_ComeBackFromTheInsert() {
		Assert.skip(Reason);
	}

	function testBinaryCopy_SaysWhyItCannotBorrowAConnection() {
		Assert.skip(Reason);
	}

	function testDisposingTheExecutor_LeavesTheContextsConnectionAlone() {
		Assert.skip(Reason);
	}
}
