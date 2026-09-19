package suites;

import codequery.SqlDate;
import codequery.migrations.*;
import codequery.migrations.DatabaseTableConstraint;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("units")
class GroupedUnit {
	public var id:Int = 0;

	public function new() {}
}

@tableName("bookings")
class GroupedBooking {
	public var id:Int = 0;
	@:foreignKey(GroupedUnit, onDelete = Cascade) public var unitId:Int = 0;
	@:index(group = "unit_check_in", order = 0) public var tenantId:Int = 0;
	@:index(group = "unit_check_in", order = 1) public var code:String = "";
	@:index public var reference:String = "";
	public var openedOn:SqlDate;

	public function new() {}
}

/**
	`IndexGroupAndForeignKeyAttributeTests.cs`: saying an index or a foreign key on the column it
	belongs to, without writing out a name. A group tag gathers the columns; the index is created
	from the columns it actually covers.
**/
class IndexGroupAndForeignKeyAttributeTests extends TestCase {
	static function Table():DatabaseTableDefinition {
		return SchemaInspector.FromType(GroupedBooking);
	}

	/** The tag gathers the columns; the name comes from the columns, in the index's own order. */
	function testAGroupedIndexIsNamedAfterTheColumnsItCovers() {
		final index = Assert.single([for (i in Table().Indexes) if (i.Columns.length == 2) i]);
		Assert.equals(["tenantId", "code"], [for (c in index.Columns) c.ColumnName]);
		Assert.equals("IX_bookings_tenantId_code", index.Name);
	}

	/** A column indexed on its own is still an index of its own, not lumped in with the group. */
	function testAnUngroupedColumnIsItsOwnIndex() {
		final single = Assert.single([for (i in Table().Indexes) if (Lambda.exists(i.Columns, c -> c.ColumnName == "reference")) i]);
		Assert.single(single.Columns);
		Assert.equals("IX_bookings_reference", single.Name);
	}

	/** The foreign key resolves its table from the type, and carries the action it was given. */
	function testAForeignKeyAttributeCarriesItsReferentialAction() {
		final fk = Assert.single([for (c in Table().Constraints) if (Std.isOfType(c, DatabaseForeignKeyConstraint)) (cast c : DatabaseForeignKeyConstraint)]);
		Assert.equals("units", fk.ReferencedTable);
		Assert.equals(["id"], fk.ReferencedColumns);
		Assert.equals(DatabaseForeignKeyAction.Cascade, fk.OnDelete);
	}

	/** An unindexed foreign key would make the database scan the child to enforce a delete. */
	function testAForeignKeyIndexesItsColumn() {
		Assert.isTrue(Lambda.exists(Table().Indexes, i -> i.Columns.length == 1 && i.Columns[0].ColumnName == "unitId"));
	}

	/** A default that constructs its value is that value. */
	function testAConstructedDefaultIsTheValueItConstructs() {
		final table = SchemaInspector.FromType(GroupedBooking);
		new EntityTableBuilder<GroupedBooking>(table).Column(b -> b.openedOn).Default(new Date(1990, 0, 1, 0, 0, 0));

		final column = Assert.single([for (c in table.Columns) if (c.Name == "openedOn") c]);
		Assert.equals("'1990-01-01'", column.DefaultValue);
	}
}
