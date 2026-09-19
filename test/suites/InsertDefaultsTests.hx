package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`InsertDefaultsTests.cs`: a column the database fills in itself, declared with
	`DbTable(schema, t => t.Column(n => n.CreatedAt).Default(() => …))`, is left out of the
	INSERT when nothing set it. Every test stores a row and reads the default back.
**/
class InsertDefaultsTests extends TestCase {
	static final Reason = "TableConfiguration.Column().Default(): column defaults not ported; needs a database: eval has none (PHP runtime only)";

	function testAnUnsetColumnTakesTheDatabaseDefault() {
		Assert.skip(Reason);
	}

	function testAValueThatWasSetIsKept() {
		Assert.skip(Reason);
	}

	function testRowsThatDifferAreInsertedApart() {
		Assert.skip(Reason);
	}

	function testTheKeyStillComesBack() {
		Assert.skip(Reason);
	}

	function testATableWithoutDefaultsIsUnchanged() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
