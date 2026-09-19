package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`PostGisTests.cs`.

	PostGIS is a PostgreSQL extension: its geometry types, functions, operators and the
	CREATE/ALTER/DROP EXTENSION migration steps are all outside the port.
**/
class PostGisTests extends TestCase {
	static inline final Reason = "PostGis: PostgreSQL extension";

	// --- Configuration ---

	function testUsePostGis_RegistersExtensionOnConfiguration() {
		Assert.skip(Reason);
	}

	function testUsePostGis_ThrowsOnNonPostgresDriver() {
		Assert.skip(Reason);
	}

	// --- Type resolution / schema inspection ---

	function testInspection_GeometryProperty_BecomesExtensionColumn() {
		Assert.skip(Reason);
	}

	function testCreateTable_GeometryColumn_RendersPostGisType_Postgres() {
		Assert.skip(Reason);
	}

	function testCreateTable_ExtensionColumn_ThrowsOnOtherDrivers() {
		Assert.skip(Reason);
	}

	// --- Migration: CREATE / ALTER / DROP EXTENSION ---

	function testCreateExtension_Renders_Postgres() {
		Assert.skip(Reason);
	}

	function testCreateExtension_ThrowsOnOtherDrivers() {
		Assert.skip(Reason);
	}

	function testDropExtension_Renders_Postgres() {
		Assert.skip(Reason);
	}

	function testAlterExtension_Renders_Postgres() {
		Assert.skip(Reason);
	}

	function testPlan_AddedExtension_EmitsCreateExtensionFirst() {
		Assert.skip(Reason);
	}

	function testPlan_ChangedExtensionVersion_EmitsAlterExtension() {
		Assert.skip(Reason);
	}

	function testPlan_RemovedExtension_EmitsDropExtensionLast() {
		Assert.skip(Reason);
	}

	function testSerialization_RoundTripsExtensions() {
		Assert.skip(Reason);
	}

	// --- Query translation ---

	function testQuery_DWithin_TranslatesToStDWithin() {
		Assert.skip(Reason);
	}

	function testQuery_Distance_InProjection_TranslatesToStDistance() {
		Assert.skip(Reason);
	}

	function testQuery_IrregularNames_TranslateCorrectly() {
		Assert.skip(Reason);
	}

	function testQuery_GeomFromText_TranslatesWithSrid() {
		Assert.skip(Reason);
	}

	// --- Custom SqlExpression (driver-supplied operator) ---

	function testRender_CustomOperatorExpression_RendersInfixOperator() {
		Assert.skip(Reason);
	}

	function testQuery_DistanceKnn_TranslatesToDistanceOperator() {
		Assert.skip(Reason);
	}

	function testQuery_BboxOperators_TranslateToInfixOperators() {
		Assert.skip(Reason);
	}
}
