package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`ObjectTypeTests.cs`: `[ColumnObject]` columns of the Native (composite type), Json and Jsonb
	kinds. The port flattens an object member into columns and has no other kind — no composite
	types, no JSON — so every test here stands aside for the feature it needs. The C# file's
	second class, `ObjectTypeBindingTests`, is the last two tests.
**/
class ObjectTypeTests extends TestCase {
	// --- Schema inspection ---

	function testInspection_ObjectTypeProperty_BecomesObjectColumn() {
		Assert.skip("ColumnObject(Native/Json/Jsonb): only Flatten is ported");
	}

	function testInspection_GetObjectTypes_ReturnsNativeTypesWithFields() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	// --- Column DDL rendering ---

	function testCreateTable_NativeObjectColumn_UsesTypeName_Postgres() {
		Assert.skip("ColumnObject(Native/Json/Jsonb): only Flatten is ported");
	}

	function testCreateTable_JsonObjectColumn_UsesDialectJsonStorage() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	function testCreateTable_NativeObjectColumn_ThrowsOnUnsupportedDrivers() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	function testCreateTable_JsonbObjectColumn_ThrowsOnUnsupportedDrivers() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	// --- CREATE TYPE / DROP TYPE rendering ---

	function testCreateType_RendersCompositeType_Postgres() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	function testCreateType_ThrowsOnUnsupportedDrivers() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	function testDropType_RendersDropTypeIfExists_Postgres() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	// --- Migration planning ---

	function testPlan_AddedType_EmitsCreateTypeBeforeCreateTable() {
		Assert.skip("MigrationPlanner/DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_RemovedType_EmitsDropTypeAfterDropTable() {
		Assert.skip("MigrationPlanner/DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_ModifiedType_AltersTheAttributeItGained() {
		Assert.skip("MigrationPlanner/DatabaseObjectTypeDefinition: composite types not ported");
	}

	// --- Snapshot serialization ---

	function testSerialization_RoundTrips_TypesAndObjectColumns() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	// --- Query translation ---

	function testQuery_NativeObjectField_RendersCompositeAccess_Postgres() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	function testQuery_NativeObjectField_ThrowsOnUnsupportedDrivers() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	function testQuery_JsonObjectField_RendersJsonExtraction_Postgres() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	function testQuery_JsonObjectField_RendersJsonExtraction_MySql() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	function testQuery_JsonbObjectField_RendersJsonExtraction_Postgres() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	function testQuery_JsonObjectField_ThroughCast_ReadsTheUnderlyingColumn() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	function testQuery_JsonObjectField_ThroughChainedSelect_ReadsTheCarriedColumn() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	// --- Value binding (serialization on insert) ---

	function testObjectConst_RendersRowLiteral_Postgres() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	function testObjectConst_ThrowsOnUnsupportedDrivers() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	// --- Materialization (fetch) ---

	function testMaterializer_ParsesCompositeLiteral() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	function testMaterializer_ParsesCompositeLiteral_WithNullsAndEscapedQuotes() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	function testMaterializer_Seam_DelegatesCompositeLiteralToPostgres() {
		Assert.skip("ColumnObject(Native): composite types not ported");
	}

	function testMaterializer_DeserializesJsonDocument() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	function testMaterializer_IgnoresScalarTargets() {
		Assert.skip("ObjectMaterializer: not ported (no fetch on eval)");
	}

	// ---- ObjectTypeBindingTests ----------------------------------------------------------------------

	function testInsert_And_Fetch_RoundTripsJsonObjectColumn() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testInsert_And_Fetch_RoundTripsPolymorphicJsonColumn() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
