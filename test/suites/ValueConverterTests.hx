package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `ValueConverterTests.cs` — custom value converters on the fluent surface. */
class ValueConverterTests extends TestCase {
	function testConvert_SetsColumnToProviderType() {
		Assert.skip("Column(…).Convert: value converters not ported");
	}

	function testInsert_And_Fetch_RoundTripsThroughConverters() {
		Assert.skip("Column(…).Convert: value converters not ported");
	}

	function testConverter_StoresProviderValue_InTheDatabase() {
		Assert.skip("Column(…).Convert: value converters not ported");
	}
}
