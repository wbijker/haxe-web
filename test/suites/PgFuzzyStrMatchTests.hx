package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `PgFuzzyStrMatchTests.cs`. fuzzystrmatch is a PostgreSQL extension, outside the port. */
class PgFuzzyStrMatchTests extends TestCase {
	static inline final Reason = "PgFuzzyStrMatch: PostgreSQL extension";

	// --- Configuration ---

	function testUseFuzzyStrMatch_RegistersTheExtensionOnTheConfiguration() {
		Assert.skip(Reason);
	}

	function testUseFuzzyStrMatch_PinsTheVersionWhenOneIsGiven() {
		Assert.skip(Reason);
	}

	function testUseFuzzyStrMatch_ThrowsOnANonPostgresDriver() {
		Assert.skip(Reason);
	}

	function testUseFuzzyStrMatch_PutsTheExtensionInTheSnapshot_SoTheMigrationCreatesIt() {
		Assert.skip(Reason);
	}

	// --- Edit distance ---

	function testLevenshtein_IsTheFunction() {
		Assert.skip(Reason);
	}

	function testLevenshtein_TakesTheThreeEditCostsWhenGiven() {
		Assert.skip(Reason);
	}

	function testLevenshteinLessEqual_IsTheBoundedFunction() {
		Assert.skip(Reason);
	}

	function testLevenshteinLessEqual_TakesTheEditCostsAndTheBound() {
		Assert.skip(Reason);
	}

	// --- Phonetic codes ---

	function testSoundex_AndDifference_AreTheirFunctions() {
		Assert.skip(Reason);
	}

	function testMetaphone_CarriesItsOutputLength() {
		Assert.skip(Reason);
	}

	function testDoubleMetaphone_KeepsItsRunTogetherName() {
		Assert.skip(Reason);
	}

	function testDaitchMokotoff_IsTheFunction() {
		Assert.skip(Reason);
	}

	// --- Run-time refusal ---

	function testCallingOneDirectlyThrows() {
		Assert.skip(Reason);
	}
}
