package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `PgUnaccentTests.cs`. The unaccent extension is a PostgreSQL extension, outside the port. */
class PgUnaccentTests extends TestCase {
	static inline final Reason = "PgUnaccent: PostgreSQL extension";

	// --- Configuration ---

	function testUseUnaccent_RegistersTheExtensionOnTheConfiguration() {
		Assert.skip(Reason);
	}

	function testUseUnaccent_ThrowsOnANonPostgresDriver() {
		Assert.skip(Reason);
	}

	function testUseUnaccent_PutsTheExtensionInTheSnapshot_SoTheMigrationCreatesIt() {
		Assert.skip(Reason);
	}

	// --- The two forms ---

	function testTheOneArgumentForm_IsThePlainFunction() {
		Assert.skip(Reason);
	}

	function testTheNamedDictionaryForm_WritesARegdictionaryReference() {
		Assert.skip(Reason);
	}

	function testTheNamedDictionaryForm_TakesADictionaryOfItsOwn() {
		Assert.skip(Reason);
	}

	function testTheNamedDictionaryForm_AcceptsACapturedName() {
		Assert.skip(Reason);
	}

	function testADictionaryReadFromTheRow_IsRefusedWithAnExplanation() {
		Assert.skip(Reason);
	}

	function testADictionaryNameIsEscaped() {
		Assert.skip(Reason);
	}

	function testCallingOneDirectlyThrows() {
		Assert.skip(Reason);
	}
}
