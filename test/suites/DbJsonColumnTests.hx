package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DbJsonColumnTests.cs`. Declaring and writing a JSON column (`[DbJsonColumn]`, `SqlType.Json`, `ConstSqlExpression.Json`): JSON is not in the port. */
class DbJsonColumnTests extends TestCase {
	static inline final Reason = "DbJsonColumn/SqlType.Json: JSON not ported";

	function testBinary_IsAJsonbColumn() {
		Assert.skip(Reason);
	}

	function testByDefault_ItIsTextJson() {
		Assert.skip(Reason);
	}

	function testTheColumnReachesTheCreateTable() {
		Assert.skip(Reason);
	}

	function testAJsonDocumentWithNothingSaidAboutIt_IsRefused_RatherThanDropped() {
		Assert.skip(Reason);
	}

	function testDbJson_NeedsNoAttribute() {
		Assert.skip(Reason);
	}

	// --- Writing one ---

	function testABoundJsonValue_SaysItIsJson() {
		Assert.skip(Reason);
	}

	function testATextJsonColumn_IsCastToJson_NotJsonb() {
		Assert.skip(Reason);
	}

	function testOtherDialectsNeedNothingSaid() {
		Assert.skip(Reason);
	}

	function testWrittenIntoTheStatement_ItIsAnUntypedLiteral() {
		Assert.skip(Reason);
	}

	function testACapturedDbJson_IsItsDocument() {
		Assert.skip(Reason);
	}
}
