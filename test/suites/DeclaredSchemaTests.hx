package suites;

import codequery.DbTable;
import codequery.Decimal;
import codequery.IDbSchema;
import codequery.execution.DatabaseConfiguration;
import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SqlBinaryOperator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.DbSchemaExtensions;
using codequery.testing.Linq;
using codequery.testing.SqlAssert;

/**
	`DeclaredSchemaTests.cs` — a schema declared as a plain class implementing `IDbSchema`: every
	member constructs itself, and nothing about it is inferred at runtime.
**/
class DeclaredSchemaTests extends TestCase {
	static function Config():DatabaseConfiguration {
		return new DatabaseConfiguration(new SqlTranslator());
	}

	static function NewDb():DsShopDb {
		return DatabaseInitializer.Build(DsShopDb, Config());
	}

	function testMembers_ConstructThemselves_OnEveryAccess() {
		Assert.skip("DbTable member getters: a Haxe schema member is a field constructed once, not a getter constructing on each access");
	}

	function testTable_UsesTableNameAttribute() {
		final db = NewDb();
		Assert.equals("widgets", db.Widgets.TableName);
		Assert.isTrue(db.Snapshot().Tables.any(t -> t.TableName == "widgets"));
	}

	function testTable_IsQueryable_WithoutBeingGivenAConfiguration() {
		final db = NewDb();

		final select = db.Widgets.From().Where(w -> w.price > 1).ToExpression();

		Assert.equals("widgets", select.selectTableName());
		select.whereClause().comparison("price", GreaterThan, 1);
	}

	function testRegisters_View_Procedure_And_Function() {
		Assert.skip("DbFunction/DbStoredProc: routines not ported");
	}

	function testMemberViewName_NamesTheView_AndTheMemberSelectsFromIt() {
		Assert.skip("DbView routines/materialized views: routines not ported");
	}

	function testTableMember_Configuration_IsApplied() {
		final db = NewDb();

		final widgets = db.Snapshot().Tables.single(t -> t.TableName == "widgets");
		Assert.isTrue(widgets.Constraints.any(c -> c.Name == "CK_widget_price"));
	}

	function testTableMember_ConfiguresTheCurrentTableSnapshot() {
		final db = DatabaseInitializer.Build(DsGizmoDb, Config());

		// The lambda saw the table as inspected from the entity — every column already there.
		Assert.equals(["id", "name", "madeOn"], DsGizmoDb.InspectedColumns);

		final gizmos = db.Snapshot().Tables.single(t -> t.TableName == "gizmos");
		final name = gizmos.Columns.single(c -> c.Name == "name");
		Assert.equals(DatabaseColumnType.VarChar, name.Type);
		Assert.equals(40, name.MaxLength);

		// The C# also partitions the table on the same builder; partitioning is not ported.
	}

	function testWholeSchemaConfiguration_IsApplied() {
		final db = DatabaseInitializer.Build(DsShopDb, Config(),
			schema -> schema.Entity(DsWidget).Column(w -> w.price).Index("IX_widget_price"));

		final widgets = db.Snapshot().Tables.single(t -> t.TableName == "widgets");
		Assert.isTrue(widgets.Indexes.any(i -> i.Name == "IX_widget_price"));
	}

	function testProcedureAndFunction_RenderTheirDdl() {
		Assert.skip("DbFunction/DbStoredProc: routines not ported");
	}

	function testRegisters_TablePartition_AndFoldsItIntoTheTable() {
		Assert.skip("Partitioning (DbTablePartition): not ported");
	}

	function testUnbuiltSchema_SaysSo_RatherThanFailingObscurely() {
		final db = new DsShopDb();

		final error = Assert.throwsMessage(() -> db.Snapshot());
		Assert.contains("DatabaseInitializer.Build", error);
	}

	function testNativeObjectColumn_RegistersCompositeType_AndEmitsCreateTypeBeforeTable() {
		Assert.skip("ColumnObject(Native)/CREATE TYPE: composite object types not ported");
	}

	/** The stored snapshot, round-tripped through JSON, diffed against the freshly built schema shows no changes. */
	function testRebuiltSchema_DiffsClean_NoSpuriousRoutineMigration() {
		final db = NewDb();

		final json = DatabaseSchemaSerializer.Serialize(db.Snapshot().ToDatabaseSchema());
		final previous = SchemaSnapshot.FromDatabaseSchema(DatabaseSchemaSerializer.Deserialize(json));

		// Routines are not ported; the tables are what the diff is over here.
		final diff = SchemaDiff.Between(previous.ToDatabaseSchema(), db.Snapshot().ToDatabaseSchema());

		Assert.empty(diff);
	}

	function testSnapshot_Stores_Rendered_Sql_Not_Structure() {
		Assert.skip("DbView/DbFunction routines: routines not ported");
	}
}

@tableName("widgets")
private class DsWidget {
	@columnPrimaryKey
	public var id:Int = 0;
	public var price:Decimal = 0;

	public function new() {}
}

/** The whole schema is this class — every member is its own construction. */
private class DsShopDb implements IDbSchema {
	// The table carries the configuration its entity's attributes can't express.
	public final Widgets:DbTable<DsWidget> = DbTable.of(w -> w.Check("CK_widget_price", x -> x.price >= 0));

	public function new() {}
}

@tableName("gizmos")
private class DsGizmo {
	@columnPrimaryKey
	public var id:Int = 0;
	public var name:String = "";
	public var madeOn:Date;

	public function new() {}
}

/** Configures from what the entity already declares — the lambda's table is the current one. */
private class DsGizmoDb implements IDbSchema {
	public static var InspectedColumns:Array<String> = [];

	public final Gizmos:DbTable<DsGizmo> = DbTable.of(table -> {
		DsGizmoDb.InspectedColumns = table.Definition.Columns.map(c -> c.Name);

		// Amends the inspected column rather than adding a second one.
		table.Column(g -> g.name).MaxLength(40).NotNull();
	});

	public function new() {}
}
