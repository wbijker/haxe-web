package suites;

import codequery.migrations.*;
import codequery.migrations.DatabaseColumnType;
import codequery.migrations.IMigrationPrompt;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`MigrationTableOrderingTests.cs`: a CREATE TABLE with a foreign key is emitted after the table it
	references, and drops go the other way — whatever order the tables were declared in.
**/
class MigrationTableOrderingTests extends TestCase {
	/** A referenced (Customer) and a referencing (Order) table, with the child listed FIRST. */
	static function ChildBeforeParent():SchemaSnapshot {
		final order = new DatabaseTableDefinition("Order");
		order.AddColumn("Id", DatabaseColumnType.Int, false);
		order.AddColumn("CustomerId", DatabaseColumnType.Int, false);
		order.PrimaryKey("PK_Order", ["Id"]);
		order.ForeignKey("FK_Order_Customer", ["CustomerId"], "Customer", ["Id"]);

		final customer = new DatabaseTableDefinition("Customer");
		customer.AddColumn("Id", DatabaseColumnType.Int, false);
		customer.PrimaryKey("PK_Customer", ["Id"]);

		return SchemaSnapshot.FromTables([order, customer]);
	}

	static function Render(ops:Array<SchemaChangeExpression>):String {
		final driver = new SqlTranslator();
		return [for (op in ops) driver.ToSql(op)].join("\n");
	}

	function testCreateTable_ReferencedTable_IsCreatedBeforeReferencingTable() {
		final ops = MigrationPlanner.Plan(SchemaDiff.Create(new SchemaSnapshot(), ChildBeforeParent()), new NonInteractiveMigrationPrompt());
		final sql = Render(ops);
		final parent = sql.indexOf("CREATE TABLE Customer");
		final child = sql.indexOf("CREATE TABLE Order");
		Assert.isTrue(parent >= 0 && child >= 0, "both tables should be created");
		Assert.isTrue(parent < child, "the referenced Customer table must be created before Order");
	}

	function testDropTable_ReferencingTable_IsDroppedBeforeReferencedTable() {
		final ops = MigrationPlanner.Plan(SchemaDiff.Create(ChildBeforeParent(), new SchemaSnapshot()), new NonInteractiveMigrationPrompt());
		final sql = Render(ops);
		final child = sql.indexOf("DROP TABLE IF EXISTS Order");
		final parent = sql.indexOf("DROP TABLE IF EXISTS Customer");
		Assert.isTrue(child >= 0 && parent >= 0, "both tables should be dropped");
		Assert.isTrue(child < parent, "the referencing Order table must be dropped before Customer");
	}

	function testDropView_IsDroppedBeforeTheTableItDependsOn() {
		final order = new DatabaseTableDefinition("Order");
		order.AddColumn("Id", DatabaseColumnType.Int, false);
		order.PrimaryKey("PK_Order", ["Id"]);

		final snapshot = SchemaSnapshot.FromTables([order]);
		snapshot.Routines.push(new DatabaseRoutineDefinition(View, "OrderView", "CREATE VIEW OrderView AS SELECT Id FROM Order"));

		final ops = MigrationPlanner.Plan(SchemaDiff.Create(snapshot, new SchemaSnapshot()), new NonInteractiveMigrationPrompt());
		var dropView = -1;
		var dropTable = -1;
		for (index in 0...ops.length) {
			if (dropView < 0 && Std.isOfType(ops[index], DropRoutineExpression)) dropView = index;
			if (dropTable < 0 && Std.isOfType(ops[index], DropTableExpression)) dropTable = index;
		}
		Assert.isTrue(dropView >= 0 && dropTable >= 0, "both the view and the table should be dropped");
		Assert.isTrue(dropView < dropTable, "the view must be dropped before the table it depends on");
	}
}
