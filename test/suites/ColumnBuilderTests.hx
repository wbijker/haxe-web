package suites;

import codequery.Decimal;
import codequery.ValueGeneration;
import codequery.inspection.SchemaInspector;
import codequery.migrations.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/**
	`ColumnBuilderTests.cs` — table configuration starts from a column: `t.Column(c -> c.x)` names it
	once with a property lambda, and its type, facets and single-column constraints hang off that.
**/
class ColumnBuilderTests extends TestCase {
	static function Builder():EntityTableBuilder<CbTrip> {
		final snapshot = new SchemaSnapshot();
		final definition = SchemaInspector.FromType(CbTrip);
		snapshot.Tables.push(definition);
		snapshot.Bind(CbTrip, definition);
		return snapshot.Entity(CbTrip);
	}

	static function Column(t:EntityTableBuilder<CbTrip>, name:String):DatabaseColumnDefinition {
		return t.Definition.Columns.single(c -> c.Name == name);
	}

	function testTheColumnIsNamedOnce_AndItsConstraintsFollowFromIt() {
		final t = Builder();

		t.Column(c -> c.tripNumber).UniqueIndex();

		final index = Assert.single(t.Definition.Indexes);
		Assert.equals("tripNumber", index.Columns.single().ColumnName);
		Assert.isTrue(index.IsUnique);
		Assert.equals("IX_trips_tripNumber", index.Name); // derived from table and column
	}

	function testAnExplicitName_WinsOverTheDerivedOne() {
		final t = Builder();

		t.Column(c -> c.tripNumber).Index("IX_truck_inbound_trip_number");

		Assert.equals("IX_truck_inbound_trip_number", Assert.single(t.Definition.Indexes).Name);
	}

	function testACheckIsWrittenOverTheColumnsOwnValue() {
		final t = Builder();

		t.Column(c -> c.distance).Check(d -> d >= 0);

		final check = Assert.single(t.Definition.Constraints.ofType(DatabaseCheckConstraint));
		Assert.equals("distance >= 0", check.Expression);
		Assert.equals("CK_trips_distance", check.Name);
	}

	function testACheckSpanningColumns_StaysOnTheTable() {
		final t = Builder();

		t.Check("CK_trips_driver_distance", x -> x.distance >= 0 && x.driverId > 0);

		final check = Assert.single(t.Definition.Constraints.ofType(DatabaseCheckConstraint));
		Assert.equals("distance >= 0 AND driverId > 0", check.Expression);
	}

	function testTypeAndFacets_ReadAsOneChain() {
		final t = Builder();

		t.Column(c -> c.tripNumber).MaxLength(40).NotNull().Default(() -> "").Comment("the trip");

		final column = Column(t, "tripNumber");
		Assert.equals(DatabaseColumnType.VarChar, column.Type);
		Assert.equals(40, column.MaxLength);
		Assert.isFalse(column.IsNullable);
		Assert.equals("''", column.DefaultValue);
		Assert.equals("the trip", column.Comment);
	}

	function testOneChain_CanCarryOnToTheNextColumn() {
		final t = Builder();

		t.Column(c -> c.tripNumber).MaxLength(40).NotNull()
			.Column(c -> c.notes).Text()
			.Column(c -> c.distance).Check(d -> d >= 0);

		Assert.equals(DatabaseColumnType.VarChar, Column(t, "tripNumber").Type);
		Assert.equals(DatabaseColumnType.Text, Column(t, "notes").Type);
		Assert.single(t.Definition.Constraints.ofType(DatabaseCheckConstraint));
	}

	function testTheColumnKeepsItsPlace_ConfiguringDoesNotAddASecondOne() {
		final t = Builder();
		final before = t.Definition.Columns.length;

		t.Column(c -> c.tripNumber).MaxLength(40);
		t.Column(c -> c.tripNumber).NotNull();

		Assert.equals(before, t.Definition.Columns.length);
		Assert.equals(40, Column(t, "tripNumber").MaxLength);
		Assert.isFalse(Column(t, "tripNumber").IsNullable);
	}

	function testAPrimaryKeyOnTheColumn_ReplacesTheInferredOne_AndCarriesItsGeneration() {
		final t = Builder();

		t.Column(c -> c.id).PrimaryKey(ValueGeneration.ClientGenerated);

		final key = Assert.single(t.Definition.Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals("id", key.Columns.single());
		Assert.equals(ValueGeneration.ClientGenerated, key.Generation);
		Assert.isFalse(Column(t, "id").IsAutoIncrement); // only a server-generated key auto-increments
	}

	function testAForeignKeyOnTheColumn_TargetsTheOtherEntitysTable() {
		final t = Builder();

		t.Column(c -> c.driverId).ForeignKey(CbDriver, d -> d.id, DatabaseForeignKeyAction.Cascade);

		final fk = Assert.single(t.Definition.Constraints.ofType(DatabaseForeignKeyConstraint));
		Assert.equals("driverId", fk.Columns.single());
		Assert.equals("CbDriver", fk.ReferencedTable);
		Assert.equals("id", fk.ReferencedColumns.single());
		Assert.equals(DatabaseForeignKeyAction.Cascade, fk.OnDelete);
		Assert.equals("FK_trips_driverId", fk.Name);
	}

	function testRenamingTheColumn_MovesTheConstraintsWithIt() {
		final t = Builder();

		t.Column(c -> c.tripNumber).Named("trip_no").Index();

		Assert.equals("trip_no", Column(t, "trip_no").Name);
		Assert.equals("trip_no", Assert.single(t.Definition.Indexes).Columns.single().ColumnName);
	}

	function testAGeneratedColumn_IsConfiguredOnTheColumnItComputes() {
		final t = Builder();

		t.Column(c -> c.distance).Generated(x -> x.driverId * 2, true);

		final column = Column(t, "distance");
		Assert.notNull(column.GeneratedExpressionTree);
		Assert.isTrue(column.GeneratedStored);
	}

	function testAConstraintOverSeveralColumns_StartsAtOneOfThemToo() {
		final t = Builder();

		t.Column(c -> c.driverId).And(c -> c.entryDate).UniqueIndex();

		final index = Assert.single(t.Definition.Indexes);
		Assert.isTrue(index.IsUnique);
		Assert.equals(["driverId", "entryDate"], index.Columns.map(c -> c.ColumnName));
		Assert.equals("IX_trips_driverId_entryDate", index.Name);
	}

	function testACompositeIndex_KeepsTheOrderAndDirectionEachColumnWasNamedWith() {
		final t = Builder();

		t.Column(c -> c.entryDate).Descending().And(c -> c.tripNumber).Index("IX_trips_recent");

		final index = Assert.single(t.Definition.Indexes);
		Assert.equals(DatabaseSortOrder.Descending, index.Columns[0].SortOrder);
		Assert.equals(DatabaseSortOrder.Ascending, index.Columns[1].SortOrder);
	}

	function testACompositePrimaryKey_StartsAtItsFirstColumn() {
		final t = Builder();

		t.Column(c -> c.id).And(c -> c.tripNumber).PrimaryKey();

		final key = Assert.single(t.Definition.Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals(["id", "tripNumber"], key.Columns);
	}

	function testPartitioningIsConfiguredOnTheColumnItPartitionsBy() {
		final t = Builder();

		t.Column(c -> c.entryDate).PartitionBy()
			.AsRange()
			.Add("trips_2025", new Date(2025, 0, 1, 0, 0, 0), new Date(2026, 0, 1, 0, 0, 0));

		Assert.equals("entryDate", t.Definition.Partition.KeyExpression);
		Assert.equals("trips_2025", Assert.single(t.Definition.Partition.Partitions).Name);
	}

	function testTheSqlTypeIsConstrainedToWhatThePropertyCouldBe() {
		// The typed builders are chosen by the property's type while compiling; what is pinned here is
		// only that the right ones work.
		final t = Builder();

		t.Column(c -> c.notes).MaxLength(100).Unicode();
		t.Column(c -> c.distance).Precision(12, 4);
		t.Column(c -> c.entryDate).Date();

		Assert.equals(DatabaseColumnType.NVarChar, Column(t, "notes").Type);
		Assert.equals(12, Column(t, "distance").Precision);
		Assert.equals(4, Column(t, "distance").Scale);
		Assert.equals(DatabaseColumnType.Date, Column(t, "entryDate").Type);
	}
}

@tableName("trips")
private class CbTrip {
	public var id:Int = 0;
	public var tripNumber:String = "";
	public var notes:Null<String>;
	public var distance:Decimal = 0;
	public var entryDate:Date;
	public var driverId:Int = 0;

	public function new() {}
}

private class CbDriver {
	public var id:Int = 0;

	public function new() {}
}
