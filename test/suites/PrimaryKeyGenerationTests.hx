package suites;

import codequery.Guid;
import codequery.ValueGeneration;
import codequery.inspection.SchemaInspector;
import codequery.migrations.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/**
	`PrimaryKeyGenerationTests.cs` — server- vs client-generated keys, and the rule that only a
	server-generated key can auto-increment.
**/
class PrimaryKeyGenerationTests extends TestCase {
	static function Pk(t:DatabaseTableDefinition):DatabasePrimaryKeyConstraint {
		return t.Constraints.ofType(DatabasePrimaryKeyConstraint).single();
	}

	static function AutoIncrement(t:DatabaseTableDefinition, column:String):Bool {
		return t.Columns.single(c -> c.Name == column).IsAutoIncrement;
	}

	// --- Convention ---

	function testIntKey_IsServerGenerated_AndAutoIncrements_ByConvention() {
		final t = SchemaInspector.FromType(PkgIntKey);
		Assert.equals(ValueGeneration.ServerGenerated, Pk(t).Generation);
		Assert.isTrue(AutoIncrement(t, "id"));
	}

	function testGuidKey_IsClientGenerated_AndNeverAutoIncrements_ByConvention() {
		final t = SchemaInspector.FromType(PkgGuidKey);
		Assert.equals(ValueGeneration.ClientGenerated, Pk(t).Generation);
		Assert.isFalse(AutoIncrement(t, "id"));
	}

	// --- Attribute ---

	function testAttribute_ClientGenerated_TurnsOffAutoIncrement_EvenForInt() {
		final t = SchemaInspector.FromType(PkgClientByAttribute);
		Assert.equals(ValueGeneration.ClientGenerated, Pk(t).Generation);
		Assert.isFalse(AutoIncrement(t, "id"));
	}

	function testAttribute_ServerGeneratedWithAutoIncrementOff_IsNotAutoIncrement() {
		final t = SchemaInspector.FromType(PkgServerNoAutoIncrement);
		Assert.equals(ValueGeneration.ServerGenerated, Pk(t).Generation);
		Assert.isFalse(AutoIncrement(t, "id"));
	}

	// --- Fluent API ---

	static function Builder():EntityTableBuilder<PkgIntKey> {
		final snapshot = new SchemaSnapshot();
		final definition = SchemaInspector.FromType(PkgIntKey);
		snapshot.Tables.push(definition);
		snapshot.Bind(PkgIntKey, definition);
		return snapshot.Entity(PkgIntKey);
	}

	function testFluent_ClientGenerated_RecordsGeneration_AndForcesAutoIncrementOff() {
		final builder = Builder();
		builder.Column(e -> e.id).PrimaryKey(ValueGeneration.ClientGenerated);

		Assert.equals(ValueGeneration.ClientGenerated, Pk(builder.Definition).Generation);
		Assert.isFalse(AutoIncrement(builder.Definition, "id")); // auto-increment is only for server-generated
	}

	function testFluent_ServerGenerated_AutoIncrementHonored() {
		final builder = Builder();
		builder.Column(e -> e.id).PrimaryKey(ValueGeneration.ServerGenerated, true);

		Assert.equals(ValueGeneration.ServerGenerated, Pk(builder.Definition).Generation);
		Assert.isTrue(AutoIncrement(builder.Definition, "id"));
	}

	function testFluent_ServerGenerated_AutoIncrementCanBeDisabled() {
		final builder = Builder();
		builder.Column(e -> e.id).PrimaryKey(ValueGeneration.ServerGenerated, false);

		Assert.isFalse(AutoIncrement(builder.Definition, "id"));
	}

	// --- JSON snapshot round-trip preserves the generation ---

	function testGeneration_SurvivesSnapshotRoundTrip() {
		final t = SchemaInspector.FromType(PkgGuidKey);
		final json = DatabaseSchemaSerializer.Serialize(SchemaSnapshot.FromTables([t]).ToDatabaseSchema());
		final restored = SchemaSnapshot.FromDatabaseSchema(DatabaseSchemaSerializer.Deserialize(json));

		Assert.equals(ValueGeneration.ClientGenerated, Pk(restored.Tables.single()).Generation);
	}
}

@tableName("ints")
private class PkgIntKey {
	public var id:Int = 0;

	public function new() {}
}

@tableName("guids")
private class PkgGuidKey {
	public var id:Guid;

	public function new() {}
}

@tableName("attr_client")
private class PkgClientByAttribute {
	@columnPrimaryKey({generation: "ClientGenerated"})
	public var id:Int = 0;

	public function new() {}
}

@tableName("attr_noinc")
private class PkgServerNoAutoIncrement {
	@columnPrimaryKey({autoIncrement: false})
	public var id:Int = 0;

	public function new() {}
}
