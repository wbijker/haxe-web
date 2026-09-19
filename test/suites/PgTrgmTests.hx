package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`PgTrgmTests.cs`.

	The pg_trgm extension is a PostgreSQL extension, and the port has no driver extensions, no
	`PostgresConfiguration` and no extension DDL — so every test here stands aside.
**/
class PgTrgmTests extends TestCase {
	static inline final Reason = "PgTrgm: PostgreSQL extension";

	// --- Configuration ---

	function testUsePgTrgm_RegistersTheExtensionOnTheConfiguration() {
		Assert.skip(Reason);
	}

	function testUsePgTrgm_PinsTheVersionWhenOneIsGiven() {
		Assert.skip(Reason);
	}

	function testUsePgTrgm_ThrowsOnANonPostgresDriver() {
		Assert.skip(Reason);
	}

	function testUsePgTrgm_PutsTheExtensionInTheSnapshot_SoTheMigrationCreatesIt() {
		Assert.skip(Reason);
	}

	function testCreateExtension_RendersForPgTrgm() {
		Assert.skip(Reason);
	}

	function testResolveSqlTypeName_ContributesNoTypes_BecauseTrigramsWorkOnPlainText() {
		Assert.skip(Reason);
	}

	// --- The six functions ---

	function testSimilarity_TranslatesToTheSimilarityFunction() {
		Assert.skip(Reason);
	}

	function testWordSimilarity_TranslatesToTheWordSimilarityFunction() {
		Assert.skip(Reason);
	}

	function testStrictWordSimilarity_TranslatesToTheStrictWordSimilarityFunction() {
		Assert.skip(Reason);
	}

	function testShowTrgm_TranslatesToTheShowTrgmFunction() {
		Assert.skip(Reason);
	}

	function testSetLimit_TranslatesToTheDeprecatedSetLimitFunction() {
		Assert.skip(Reason);
	}

	function testShowLimit_TranslatesToTheDeprecatedShowLimitFunction() {
		Assert.skip(Reason);
	}

	function testSetLimitAndShowLimit_AreMarkedObsolete_PointingAtTheGucs() {
		Assert.skip(Reason);
	}

	// --- The similarity operators (symmetric) ---

	function testIsSimilarTo_TranslatesToThePercentOperator() {
		Assert.skip(Reason);
	}

	function testDistanceTo_TranslatesToTheDistanceOperator() {
		Assert.skip(Reason);
	}

	// --- The word similarity operators (asymmetric) ---

	function testIsWordSimilarTo_PutsTheProbeOnTheLeft() {
		Assert.skip(Reason);
	}

	function testContainsWordSimilarTo_MirrorsIt_SoTheIndexedColumnCanBeOnTheLeft() {
		Assert.skip(Reason);
	}

	function testWordDistanceTo_TranslatesToTheProbeOnTheLeftDistance() {
		Assert.skip(Reason);
	}

	function testWordDistanceFrom_TranslatesToTheMirroredDistance() {
		Assert.skip(Reason);
	}

	// --- The strict word similarity operators (asymmetric) ---

	function testIsStrictWordSimilarTo_PutsTheProbeOnTheLeft() {
		Assert.skip(Reason);
	}

	function testContainsStrictWordSimilarTo_MirrorsIt() {
		Assert.skip(Reason);
	}

	function testStrictWordDistanceTo_TranslatesToTheProbeOnTheLeftDistance() {
		Assert.skip(Reason);
	}

	function testStrictWordDistanceFrom_TranslatesToTheMirroredDistance() {
		Assert.skip(Reason);
	}

	function testRender_OperatorExpression_RendersInfix_ThroughTheExtensionsRenderHook() {
		Assert.skip(Reason);
	}

	// --- The thresholds the boolean operators compare against ---

	function testSimilarityThreshold_ReadsTheGuc() {
		Assert.skip(Reason);
	}

	function testWordSimilarityThreshold_ReadsTheGuc() {
		Assert.skip(Reason);
	}

	function testStrictWordSimilarityThreshold_ReadsTheGuc() {
		Assert.skip(Reason);
	}

	function testSetTrgmThreshold_SetsTheGucItsFamilyReads_Similarity() {
		Assert.skip(Reason);
	}

	function testSetTrgmThreshold_SetsTheGucItsFamilyReads_WordSimilarity() {
		Assert.skip(Reason);
	}

	function testSetTrgmThreshold_SetsTheGucItsFamilyReads_StrictWordSimilarity() {
		Assert.skip(Reason);
	}

	function testSetTrgmThreshold_ForTheWholeSession_IsAskedFor() {
		Assert.skip(Reason);
	}

	function testSetTrgmThreshold_RejectsAValueThatIsNotASimilarity_BelowZero() {
		Assert.skip(Reason);
	}

	function testSetTrgmThreshold_RejectsAValueThatIsNotASimilarity_AboveOne() {
		Assert.skip(Reason);
	}

	// --- Index DDL ---

	function testCreateTrgmIndex_Gin_RendersTheGinOperatorClass() {
		Assert.skip(Reason);
	}

	function testCreateTrgmIndex_Gist_RendersTheGistOperatorClass_WhichServesTheDistanceOperators() {
		Assert.skip(Reason);
	}

	function testCreateTrgmIndex_Gist_CarriesTheSignatureLength() {
		Assert.skip(Reason);
	}

	function testCreateTrgmIndex_CoversSeveralColumns_AndQualifiesTheTable() {
		Assert.skip(Reason);
	}

	function testCreateTrgmIndex_RejectsASignatureLengthOnGin_WhichHasNoSuchOption() {
		Assert.skip(Reason);
	}

	function testCreateTrgmIndex_RejectsANonPositiveSignatureLength() {
		Assert.skip(Reason);
	}

	function testCreateTrgmIndex_RejectsAnEmptyColumnList() {
		Assert.skip(Reason);
	}

	// --- The index declared on the table ---

	function testHasTrigramIndex_DeclaresAGinIndexOnTheTable_WithAnUndo() {
		Assert.skip(Reason);
	}

	function testHasTrigramIndex_Gist_GetsItsOwnName_SoBothIndexesCanCoexist() {
		Assert.skip(Reason);
	}

	function testHasTrigramIndex_TakesAnExplicitName() {
		Assert.skip(Reason);
	}

	function testMigration_CreatesTheExtension_ThenTheTable_ThenTheIndexes() {
		Assert.skip(Reason);
	}

	function testSnapshot_RoundTripsTheIndexStatements_SoNoMigrationIsScaffoldedTwice() {
		Assert.skip(Reason);
	}
}
