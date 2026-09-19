package suites;

import codequery.migrations.*;
import codequery.migrations.IMigrationPrompt;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("widgets")
class WidgetBefore {
	public var id:Int = 0;
	public var name:String = "";
	public var price:Float = 0;
	public var sku:String = "";

	public function new() {}
}

/** The same table with one column inserted second. */
@tableName("widgets")
class WidgetAfter {
	public var id:Int = 0;
	public var category:String = "";
	public var name:String = "";
	public var price:Float = 0;
	public var sku:String = "";

	public function new() {}
}

/**
	`SnapshotOrdinalNoiseTests.cs`: what inserting a column does to the snapshot file. The file
	already says the order by the order it lists them in, so the ordinal is not written down.
**/
class SnapshotOrdinalNoiseTests extends TestCase {
	static function Yaml(table:DatabaseTableDefinition):String {
		return SnapshotSerializer.Serialize(SchemaSnapshotDocument.FromModel(SchemaCanonicalizer.Canonical(SchemaSnapshot.FromTables([table]))));
	}

	static function Snapshot(table:DatabaseTableDefinition):SchemaSnapshot {
		return SchemaSnapshot.FromDatabaseSchema(SnapshotSerializer.Deserialize(Yaml(table)).ToModel());
	}

	function testASnapshotWrittenWhenTheOrdinalWasStored_StillReadsTheSameWay() {
		final old = [
			"version: 1",
			"tables:",
			"- name: widgets",
			"  columns:",
			"  - name: Id",
			"    type: Int",
			"    nullable: false",
			"    ordinal: 0",
			"  - name: Name",
			"    type: VarChar",
			"    nullable: true",
			"    ordinal: 1",
			"  - name: Sku",
			"    type: VarChar",
			"    nullable: true",
			"    ordinal: 2"
		].join("\n");

		final columns = Assert.single(SchemaSnapshot.FromDatabaseSchema(SnapshotSerializer.Deserialize(old).ToModel()).Tables).Columns;
		Assert.equals(["Id", "Name", "Sku"], [for (c in columns) c.Name]);
		Assert.equals([0, 1, 2], [for (c in columns) c.OrdinalIndex]);
	}

	function testInsertingAColumn_AddsLines_AndChangesNoOthers() {
		final before = Yaml(SchemaInspector.FromType(WidgetBefore)).split("\n");
		final after = Yaml(SchemaInspector.FromType(WidgetAfter)).split("\n");

		// Every line of the old file still appears in the new one, in order: an insertion and nothing else.
		var remaining = after.copy();
		for (line in before) {
			final at = remaining.indexOf(line);
			Assert.isTrue(at >= 0, 'a line the insert should not have touched changed: ${StringTools.trim(line)}');
			remaining = remaining.slice(at + 1);
		}
	}

	function testTheFileDoesNotWriteTheOrdinalDown() {
		Assert.doesNotContain("ordinal", Yaml(SchemaInspector.FromType(WidgetBefore)).toLowerCase());
	}

	function testTheOrdinalIsStillReadBack_SoARenameIsStillToldFromADropAndAnAdd() {
		final columns = Assert.single(Snapshot(SchemaInspector.FromType(WidgetBefore)).Tables).Columns;
		Assert.equals(["id", "name", "price", "sku"], [for (c in columns) c.Name]);
		Assert.equals([0, 1, 2, 3], [for (c in columns) c.OrdinalIndex]);
	}

	function testAColumnInsertedInTheMiddle_IsAnAddAndNotARename() {
		final ops = MigrationPlanner.Plan(SchemaDiff.Create(Snapshot(SchemaInspector.FromType(WidgetBefore)),
			Snapshot(SchemaInspector.FromType(WidgetAfter))), new NonInteractiveMigrationPrompt());

		Assert.isTrue(Lambda.exists(ops, o -> {
			final add = Std.downcast(o, AddColumnExpression);
			add != null && add.Column.Name == "category";
		}));
		Assert.isFalse(Lambda.exists(ops, o -> Std.isOfType(o, RenameColumnExpression)));
		Assert.isFalse(Lambda.exists(ops, o -> Std.isOfType(o, DropColumnExpression)));
	}
}
