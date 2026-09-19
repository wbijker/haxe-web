package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`ObjectTypeMigrationTests.cs`: how the planner alters a composite type a table already uses.
	The port has no composite types — an object member is flattened into columns — so there is no
	`DatabaseObjectTypeDefinition` to diff and nothing here can run.
**/
class ObjectTypeMigrationTests extends TestCase {
	function testPlan_AttributeAddedAndDropped_AltersTheTypeInPlace() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_AttributeRetyped_WhenNothingUsesTheType_RetypesIt() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_AttributeRetyped_WhileAColumnUsesTheType_SaysWhichColumn() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_EnumTypeChanged_StillDropsAndCreates() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testToSql_CarriesCascadeOnEveryAction_NotOnceAtTheEnd() {
		Assert.skip("AlterObjectTypeExpression: composite types not ported");
	}

	// ---- renaming a type ------------------------------------------------------------------------------

	function testPlan_TypeGoneAndTypeArrived_WithTheColumnMovedOver_IsARename() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_ATypeStillDeclaredBySomeColumn_IsNotARename() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_ATypeNoColumnFollowed_IsNotARename() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_TypeRenamedAndReshaped_RenamesFirstAndAltersUnderTheNewName() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	// ---- renaming an attribute -------------------------------------------------------------------------

	function testPlan_OneAttributeGoneAndOneArrivedOfItsType_IsARename() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_AnAttributeRenamedAndAnotherAdded_AreSeparateStatements() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_AnAttributeWithTwoItCouldHaveBecome_IsNotGuessedAt() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	function testPlan_AnAttributeThatChangedTypeAsWellAsName_IsNotARename() {
		Assert.skip("DatabaseObjectTypeDefinition: composite types not ported");
	}

	// ---- how the renames are written -------------------------------------------------------------------

	function testToSql_RenamingAType_NeedsNoCascade() {
		Assert.skip("RenameObjectTypeExpression: composite types not ported");
	}

	function testToSql_RenamingAnAttribute_CascadesIntoTheTablesHoldingIt() {
		Assert.skip("RenameObjectTypeAttributeExpression: composite types not ported");
	}

	function testToSql_ADialectWithoutCompositeTypes_SaysSoRatherThanWritingSomething() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}
}
