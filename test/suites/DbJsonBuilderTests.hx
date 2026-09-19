package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DbJsonBuilderTests.cs`. `DbJsonObject`/`DbJsonArray` build a `DbJson` document: JSON is not in the port. */
class DbJsonBuilderTests extends TestCase {
	static inline final Reason = "DbJsonObject/DbJson: JSON not ported";

	function testEachTypeIsWrittenAsTheJsonItIs() {
		Assert.skip(Reason);
	}

	function testADateIsIso8601() {
		Assert.skip(Reason);
	}

	function testObjectsAndArraysNest() {
		Assert.skip(Reason);
	}

	function testItCanBeBuiltAStepAtATime() {
		Assert.skip(Reason);
	}

	function testANestedObjectIsStillTheSameObject() {
		Assert.skip(Reason);
	}

	function testSettingAKeyTwiceReplacesItWhereItWas() {
		Assert.skip(Reason);
	}

	function testWhatWasSetCanBeReadBackAndRemoved() {
		Assert.skip(Reason);
	}

	// --- From a dictionary ---

	function testADictionaryIsADocument() {
		Assert.skip(Reason);
	}

	function testADictionaryConvertsItsWholeTree() {
		Assert.skip(Reason);
	}

	function testATypedMapIsAnObjectToo() {
		Assert.skip(Reason);
	}

	function testADictionaryTakesABuiltObjectAsAValue() {
		Assert.skip(Reason);
	}

	// --- What it is once it is built ---

	function testTextIsEscaped() {
		Assert.skip(Reason);
	}

	function testABuiltDocumentIsAJsonConstant() {
		Assert.skip(Reason);
	}

	function testItIsValidJson() {
		Assert.skip(Reason);
	}
}
