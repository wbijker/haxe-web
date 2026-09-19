package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DbGeneratedValueTests.cs` — reading a generated column without saying `Value()`. */
class DbGeneratedValueTests extends TestCase {
	function testItReadsAsItsValueWhereTheTypeIsKnown() {
		Assert.skip("DbGenerated<T>: generated-column property type not ported");
	}

	function testItReadsAsItsValueInAPredicate() {
		Assert.skip("DbGenerated<T>: generated-column property type not ported");
	}

	function testValueSaysTheSameThing() {
		Assert.skip("DbGenerated<T>: generated-column property type not ported");
	}

	function testAnAnonymousProjectionIsStillTheColumn() {
		Assert.skip("DbGenerated<T>: generated-column property type not ported");
	}

	function testAReadRowCarriesTheValue() {
		Assert.skip("RowMapper: row mapping not ported");
	}
}
