package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `EfSourceExtractionTests.cs`. */
class EfSourceExtractionTests extends TestCase {
	static final Reason = "EntityFramework: not ported";

	function testToTable_IsTheSourceName() {
		Assert.skip(Reason);
	}

	function testWithoutAnExplicitMapping_TheDbSetNamesTheTable() {
		Assert.skip(Reason);
	}

	function testColumns_CarryTheirPropertyAndColumnNames() {
		Assert.skip(Reason);
	}

	function testTheKeyColumn_IsFlagged() {
		Assert.skip(Reason);
	}

	function testAViewMappedEntity_SelectsFromTheView() {
		Assert.skip(Reason);
	}

	function testCodeQuerySources_ListsEveryMappedEntity() {
		Assert.skip(Reason);
	}

	function testATypeTheModelDoesNotMap_NamesTheOnesItDoes() {
		Assert.skip(Reason);
	}

	function testASource_IsExtractedOncePerModel() {
		Assert.skip(Reason);
	}
}
