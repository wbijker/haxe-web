package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `EfDbSetQueryExtensionTests.cs`. */
class EfDbSetQueryExtensionTests extends TestCase {
	static final Reason = "EntityFramework: not ported";

	function testASet_IsTheTableAQueryStartsFrom() {
		Assert.skip(Reason);
	}

	function testASet_IsAJoinSource() {
		Assert.skip(Reason);
	}

	function testASet_IsAKeyBasedJoinSource() {
		Assert.skip(Reason);
	}

	function testASet_IsASetOperationSource() {
		Assert.skip(Reason);
	}

	function testASet_IsAnExistsSource() {
		Assert.skip(Reason);
	}

	function testASet_IsACrossJoinSource() {
		Assert.skip(Reason);
	}

	function testASet_StartsAnUpdateAndADelete() {
		Assert.skip(Reason);
	}

	function testEfsOwnUpdate_StillTracks() {
		Assert.skip(Reason);
	}

	function testLinqOperators_AreUntouched() {
		Assert.skip(Reason);
	}
}
