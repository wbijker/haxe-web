package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `InsertDefaultsMappedColumnTests.cs`: a database default on a column named from outside the type. */
class InsertDefaultsMappedColumnTests extends TestCase {
	function testAMappedColumnStillTakesItsDatabaseDefault() {
		Assert.skip("EntityColumnNames: names registered from outside the type are not ported; needs a database: eval has none (PHP runtime only)");
	}
}
