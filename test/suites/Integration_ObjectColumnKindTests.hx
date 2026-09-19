package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`Integration/ObjectColumnKindTests.cs`.

	The three kinds of object column the database holds in one column — JSON, JSONB and a native
	composite. This port has only the fourth kind, the flattened one (see
	`Integration_FlattenObjectTests`); `@columnObject(Json | Jsonb | Native)` is not here.
**/
class Integration_ObjectColumnKindTests extends TestCase {
	static final Json = "JsonExpression: JSON not ported";
	static final Native = "ObjectTypeKind.Native: composite types not ported";
	static final Database = "needs a database: eval has none (PHP runtime only)";

	// ---- one column, whichever kind ---------------------------------------------------------

	function testAJsonObjectSelected_IsTheOneColumnHoldingIt_AsJson() {
		Assert.skip(Json);
	}

	function testAJsonObjectSelected_IsTheOneColumnHoldingIt_AsJsonb() {
		Assert.skip(Json);
	}

	function testANativeObjectSelected_IsAskedForAsItsLiteral() {
		Assert.skip(Native);
	}

	function testTheObjectSelectedUnderAnotherName_IsStillTheOneColumn() {
		Assert.skip(Json);
	}

	function testAFieldOfAJsonObject_ReachesIntoTheColumn() {
		Assert.skip(Json);
	}

	function testAFieldOfANativeObject_ReachesIntoTheColumn() {
		Assert.skip(Native);
	}

	// ---- there and back again ---------------------------------------------------------------

	function testEachKindWritten_IsReadBackWhole() {
		Assert.skip(Database);
	}

	function testAJsonObjectSelectedOnItsOwn_IsDeserialisedIntoItsType() {
		Assert.skip(Database);
	}

	function testANativeObjectSelectedOnItsOwn_IsParsedIntoItsType() {
		Assert.skip(Database);
	}

	function testAnObjectSelectedUnderAnotherName_IsReadBackIntoThatMember() {
		Assert.skip(Database);
	}
}
