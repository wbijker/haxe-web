package suites;

import codequery.migrations.*;
import codequery.migrations.DatabaseColumnType;
import codequery.migrations.IMigrationPrompt;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

class FakePrompt implements IMigrationPrompt {
	final table:Null<String>;
	final column:Null<String>;

	public function new(?table:String, ?column:String) {
		this.table = table;
		this.column = column;
	}

	public function ResolveTableRename(addedTable:String, droppedCandidates:Array<String>):Null<String> {
		return table;
	}

	public function ResolveColumnRename(tableName:String, addedColumn:String, droppedCandidates:Array<String>):Null<String> {
		return column;
	}
}

/** `MigrationPlannerTests.cs`. */
class MigrationPlannerTests extends TestCase {
	static function Diff(from:Null<DatabaseTableDefinition>, to:DatabaseTableDefinition):SchemaDiff {
		final fromSnap = from == null ? null : SchemaSnapshot.FromTables([from]);
		return SchemaDiff.Create(fromSnap, SchemaSnapshot.FromTables([to]));
	}

	static function Users(table:String = "users"):DatabaseTableDefinition {
		return new DatabaseTableDefinition(table).AddColumn("Id", DatabaseColumnType.Int, false).AddColumn("Name", DatabaseColumnType.VarChar);
	}

	static function has<T:{}>(ops:Array<SchemaChangeExpression>, cls:Class<T>):Bool {
		return Lambda.exists(ops, o -> Std.isOfType(o, cls));
	}

	function testPlan_ColumnRename_WhenPromptConfirms_EmitsRenameNotDropAdd() {
		final to = new DatabaseTableDefinition("users").AddColumn("Id", DatabaseColumnType.Int, false).AddColumn("FullName", DatabaseColumnType.VarChar);
		final ops = MigrationPlanner.Plan(Diff(Users(), to), new FakePrompt(null, "Name"));
		Assert.isTrue(has(ops, RenameColumnExpression));
		Assert.isFalse(has(ops, DropColumnExpression));
		Assert.isFalse(has(ops, AddColumnExpression));
	}

	function testPlan_ColumnRename_WhenPromptDeclines_EmitsDropAndAdd() {
		// The rename candidate sits at a different ordinal than the dropped column, so ordinal matching
		// cannot auto-resolve it and the (declining) prompt is consulted — yielding a drop + add.
		final to = new DatabaseTableDefinition("users").AddColumn("FullName", DatabaseColumnType.VarChar).AddColumn("Id", DatabaseColumnType.Int, false);
		final ops = MigrationPlanner.Plan(Diff(Users(), to), new FakePrompt());
		Assert.isFalse(has(ops, RenameColumnExpression));
		Assert.isTrue(has(ops, DropColumnExpression));
		Assert.isTrue(has(ops, AddColumnExpression));
	}

	function testPlan_ColumnRename_SameOrdinal_AlterCompatible_AutoRenames_WithoutPrompt() {
		final to = new DatabaseTableDefinition("users").AddColumn("Id", DatabaseColumnType.Int, false).AddColumn("FullName", DatabaseColumnType.VarChar);
		final ops = MigrationPlanner.Plan(Diff(Users(), to), new FakePrompt());
		Assert.isTrue(Lambda.exists(ops, o -> {
			final r = Std.downcast(o, RenameColumnExpression);
			r != null && r.OldColumnName == "Name" && r.NewColumnName == "FullName";
		}));
		Assert.isFalse(has(ops, DropColumnExpression));
		Assert.isFalse(has(ops, AddColumnExpression));
	}

	function testPlan_ColumnRename_SameOrdinal_WideningType_EmitsRenameAndAlter() {
		final to = new DatabaseTableDefinition("users").AddColumn("Id", DatabaseColumnType.Int, false).AddColumn("Nickname", DatabaseColumnType.Text);
		final ops = MigrationPlanner.Plan(Diff(Users(), to), new FakePrompt());
		Assert.isTrue(Lambda.exists(ops, o -> {
			final r = Std.downcast(o, RenameColumnExpression);
			r != null && r.OldColumnName == "Name" && r.NewColumnName == "Nickname";
		}));
		Assert.isTrue(has(ops, AlterColumnExpression));
		Assert.isFalse(has(ops, DropColumnExpression));
		Assert.isFalse(has(ops, AddColumnExpression));
	}

	function testPlan_SameOrdinal_IncompatibleTypeChange_EmitsDropAndAdd() {
		final to = new DatabaseTableDefinition("users").AddColumn("Id", DatabaseColumnType.Int, false).AddColumn("Age", DatabaseColumnType.Int);
		final ops = MigrationPlanner.Plan(Diff(Users(), to), new FakePrompt());
		Assert.isFalse(has(ops, RenameColumnExpression));
		Assert.isTrue(has(ops, DropColumnExpression));
		Assert.isTrue(has(ops, AddColumnExpression));
	}

	function testPlan_TableRename_WhenPromptConfirms_EmitsRenameTable() {
		final ops = MigrationPlanner.Plan(Diff(Users("users"), Users("members")), new FakePrompt("users"));
		Assert.isTrue(has(ops, RenameTableExpression));
		Assert.isFalse(has(ops, DropTableExpression));
		Assert.isFalse(has(ops, CreateTableExpression));
	}

	function testPlan_NewTable_EmitsCreateTable() {
		final ops = MigrationPlanner.Plan(Diff(null, Users()), new FakePrompt());
		Assert.isTrue(has(ops, CreateTableExpression));
	}
}
