package suites;

import codequery.DateTimeOffset;
import codequery.Decimal;
import codequery.Guid;
import codequery.Single;
import codequery.SmallInt;
import codequery.TimeSpan;
import codequery.TinyInt;
import codequery.migrations.*;
import codequery.schemabuilder.DatabaseBuilder;
import codequery.schemabuilder.DatabaseTableBuilder;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.SqlType;
import codequery.sqlexpressions.TableConstraint;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/** `DatabaseTableBuilderTests.cs`. */
class DatabaseTableBuilderTests extends TestCase {
	function typed():DatabaseTableBuilder<DtbTestEntity> {
		return new DatabaseBuilder().AddTable(DtbTestEntity);
	}

	// ---- Integer Property Tests ----

	function testProperty_Int_CreatesIntColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.id);
		final table = tableBuilder.Build();
		final column = Assert.single(table.Columns);
		Assert.equals("id", column.Name);
		Assert.equals(DatabaseColumnType.Int, column.Type);
		Assert.isFalse(column.IsNullable);
	}

	function testProperty_NullableInt_CreatesNullableColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.nullableInt);
		final column = Assert.single(tableBuilder.Build().Columns);
		Assert.isTrue(column.IsNullable);
	}

	function testProperty_Long_CreatesBigIntColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.bigId);
		Assert.equals(DatabaseColumnType.BigInt, Assert.single(tableBuilder.Build().Columns).Type);
	}

	function testProperty_Short_CreatesSmallIntColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.smallNumber);
		Assert.equals(DatabaseColumnType.SmallInt, Assert.single(tableBuilder.Build().Columns).Type);
	}

	function testProperty_Byte_CreatesTinyIntColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.tinyNumber);
		Assert.equals(DatabaseColumnType.TinyInt, Assert.single(tableBuilder.Build().Columns).Type);
	}

	// ---- Floating Point Property Tests ----

	function testProperty_Float_CreatesFloatColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.floatValue);
		Assert.equals(DatabaseColumnType.Float, Assert.single(tableBuilder.Build().Columns).Type);
	}

	function testProperty_Double_CreatesDoubleColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.doubleValue);
		Assert.equals(DatabaseColumnType.Double, Assert.single(tableBuilder.Build().Columns).Type);
	}

	function testProperty_Decimal_CreatesDecimalColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.decimalValue);
		final column = Assert.single(tableBuilder.Build().Columns);
		Assert.equals(DatabaseColumnType.Decimal, column.Type);
		Assert.equals(18, column.Precision);
		Assert.equals(2, column.Scale);
	}

	// ---- String and Boolean Property Tests ----

	function testProperty_String_CreatesVarCharColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.stringValue);
		final column = Assert.single(tableBuilder.Build().Columns);
		Assert.equals(DatabaseColumnType.VarChar, column.Type);
		Assert.isNull(column.MaxLength);
		Assert.isTrue(column.IsNullable);
	}

	function testProperty_Bool_CreatesBooleanColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.boolValue);
		final column = Assert.single(tableBuilder.Build().Columns);
		Assert.equals(DatabaseColumnType.Boolean, column.Type);
		Assert.isFalse(column.IsNullable);
	}

	function testProperty_NullableBool_CreatesNullableColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.nullableBool);
		Assert.isTrue(Assert.single(tableBuilder.Build().Columns).IsNullable);
	}

	// ---- DateTime Property Tests ----

	function testProperty_DateTime_CreatesDateTimeColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.dateTimeValue);
		Assert.equals(DatabaseColumnType.DateTime, Assert.single(tableBuilder.Build().Columns).Type);
	}

	function testProperty_DateTimeOffset_CreatesDateTimeOffsetColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.dateTimeOffsetValue);
		Assert.equals(DatabaseColumnType.DateTimeOffset, Assert.single(tableBuilder.Build().Columns).Type);
	}

	function testProperty_TimeSpan_CreatesTimeColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.timeSpanValue);
		Assert.equals(DatabaseColumnType.Time, Assert.single(tableBuilder.Build().Columns).Type);
	}

	// ---- Special Type Property Tests ----

	function testProperty_Guid_CreatesGuidColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.guidValue);
		Assert.equals(DatabaseColumnType.Guid, Assert.single(tableBuilder.Build().Columns).Type);
	}

	function testProperty_ByteArray_CreatesBinaryColumn() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.binaryValue);
		final column = Assert.single(tableBuilder.Build().Columns);
		Assert.equals(DatabaseColumnType.VarBinary, column.Type);
		Assert.isTrue(column.IsNullable);
	}

	// ---- Primary Key Tests ----

	function testHasPrimaryKey_SingleColumn_CreatesConstraint() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.id);
		tableBuilder.HasPrimaryKey(e -> e.id);
		final table = tableBuilder.Build();
		final pk = Assert.single(table.Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals("PK_DtbTestEntity", pk.Name);
		Assert.single(pk.Columns);
		Assert.equals("id", pk.Columns[0]);
	}

	function testHasPrimaryKey_WithCustomName_UsesProvidedName() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.id);
		tableBuilder.HasPrimaryKey("PK_Custom", e -> e.id);
		final pk = Assert.single(tableBuilder.Build().Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals("PK_Custom", pk.Name);
	}

	function testHasPrimaryKey_CompositeKey_CreatesMultiColumnConstraint() {
		final tableBuilder = new DatabaseBuilder().AddTable(DtbCompositeKeyEntity);
		tableBuilder.Property(e -> e.key1);
		tableBuilder.Property(e -> e.key2);
		tableBuilder.HasPrimaryKey(e -> e.key1, e -> e.key2);
		final pk = Assert.single(tableBuilder.Build().Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals(2, pk.Columns.length);
		Assert.isTrue(pk.Columns.indexOf("key1") >= 0);
		Assert.isTrue(pk.Columns.indexOf("key2") >= 0);
	}

	// ---- Foreign Key Tests ----

	function testHasForeignKey_CreatesConstraint() {
		final builder = new DatabaseBuilder();
		final parentTable = builder.AddTable(DtbParentEntity, "Parents");
		parentTable.Property(p -> p.id);
		parentTable.Build();

		final childTable = builder.AddTable(DtbChildEntity, "Children");
		childTable.Property(c -> c.id);
		childTable.Property(c -> c.parentId);
		childTable.HasForeignKey(DtbParentEntity, c -> c.parentId, p -> p.id);
		final table = childTable.Build();

		final fk = Assert.single(table.Constraints.ofType(DatabaseForeignKeyConstraint));
		Assert.equals("parentId", fk.Columns[0]);
		Assert.equals("Parents", fk.ReferencedTable);
		Assert.equals("id", fk.ReferencedColumns[0]);
	}

	function testHasForeignKey_WithActions_SetsDeleteAndUpdateActions() {
		final builder = new DatabaseBuilder();
		final parentTable = builder.AddTable(DtbParentEntity, "Parents");
		parentTable.Property(p -> p.id);
		parentTable.Build();

		final childTable = builder.AddTable(DtbChildEntity, "Children");
		childTable.Property(c -> c.id);
		childTable.Property(c -> c.parentId);
		childTable.HasForeignKey(DtbParentEntity, c -> c.parentId, p -> p.id, DatabaseForeignKeyAction.Cascade, DatabaseForeignKeyAction.Restrict);
		final table = childTable.Build();

		final fk = Assert.single(table.Constraints.ofType(DatabaseForeignKeyConstraint));
		Assert.equals(DatabaseForeignKeyAction.Cascade, fk.OnDelete);
		Assert.equals(DatabaseForeignKeyAction.Restrict, fk.OnUpdate);
	}

	function testHasForeignKey_WithCustomName_UsesProvidedName() {
		final builder = new DatabaseBuilder();
		final parentTable = builder.AddTable(DtbParentEntity, "Parents");
		parentTable.Property(p -> p.id);
		parentTable.Build();

		final childTable = builder.AddTable(DtbChildEntity, "Children");
		childTable.Property(c -> c.id);
		childTable.Property(c -> c.parentId);
		childTable.HasForeignKey("FK_Custom", DtbParentEntity, c -> c.parentId, p -> p.id);
		final table = childTable.Build();

		final fk = Assert.single(table.Constraints.ofType(DatabaseForeignKeyConstraint));
		Assert.equals("FK_Custom", fk.Name);
	}

	// ---- Unique Constraint Tests ----

	function testHasUnique_SingleColumn_CreatesConstraint() {
		final tableBuilder = new DatabaseBuilder().AddTable(DtbParentEntity);
		tableBuilder.Property(p -> p.name);
		tableBuilder.HasUnique(p -> p.name);
		final uq = Assert.single(tableBuilder.Build().Constraints.ofType(DatabaseUniqueConstraint));
		Assert.equals("UQ_DtbParentEntity_name", uq.Name);
		Assert.single(uq.Columns);
		Assert.equals("name", uq.Columns[0]);
	}

	function testHasUnique_MultipleColumns_CreatesCompositeConstraint() {
		final tableBuilder = new DatabaseBuilder().AddTable(DtbCompositeKeyEntity);
		tableBuilder.Property(e -> e.key1);
		tableBuilder.Property(e -> e.key2);
		tableBuilder.HasUnique(e -> e.key1, e -> e.key2);
		final uq = Assert.single(tableBuilder.Build().Constraints.ofType(DatabaseUniqueConstraint));
		Assert.equals(2, uq.Columns.length);
	}

	function testHasUnique_WithCustomName_UsesProvidedName() {
		final tableBuilder = new DatabaseBuilder().AddTable(DtbParentEntity);
		tableBuilder.Property(p -> p.name);
		tableBuilder.HasUnique("UQ_Custom", p -> p.name);
		final uq = Assert.single(tableBuilder.Build().Constraints.ofType(DatabaseUniqueConstraint));
		Assert.equals("UQ_Custom", uq.Name);
	}

	// ---- Check Constraint Tests ----

	function testHasCheck_CreatesCheckConstraint() {
		final tableBuilder = typed();
		tableBuilder.Property(e -> e.decimalValue);
		tableBuilder.HasCheck("CK_Positive", e -> e.decimalValue > 0);
		final ck = Assert.single(tableBuilder.Build().Constraints.ofType(DatabaseCheckConstraint));
		Assert.equals("CK_Positive", ck.Name);
		Assert.equals("decimalValue > 0", ck.Expression);
	}

	// ---- Index Tests ----

	function testHasIndex_SingleColumn_CreatesIndex() {
		final tableBuilder = new DatabaseBuilder().AddTable(DtbParentEntity);
		tableBuilder.Property(p -> p.name);
		tableBuilder.HasIndex(p -> p.name);
		final idx = Assert.single(tableBuilder.Build().Indexes);
		Assert.equals("IX_DtbParentEntity_name", idx.Name);
		Assert.single(idx.Columns);
		Assert.equals("name", idx.Columns[0].ColumnName);
	}

	function testHasIndex_MultipleColumns_CreatesCompositeIndex() {
		final tableBuilder = new DatabaseBuilder().AddTable(DtbCompositeKeyEntity);
		tableBuilder.Property(e -> e.key1);
		tableBuilder.Property(e -> e.key2);
		tableBuilder.HasIndex(e -> e.key1, e -> e.key2);
		final idx = Assert.single(tableBuilder.Build().Indexes);
		Assert.equals(2, idx.Columns.length);
	}

	function testHasIndex_WithCustomName_UsesProvidedName() {
		final tableBuilder = new DatabaseBuilder().AddTable(DtbParentEntity);
		tableBuilder.Property(p -> p.name);
		tableBuilder.HasIndex("IX_Custom", p -> p.name);
		final idx = Assert.single(tableBuilder.Build().Indexes);
		Assert.equals("IX_Custom", idx.Name);
	}

	function testHasIndex_WithBuilder_ConfiguresIndex() {
		final tableBuilder = new DatabaseBuilder().AddTable(DtbParentEntity);
		tableBuilder.Property(p -> p.name);
		tableBuilder.HasIndex("IX_Custom", idx -> idx.Column("name").Unique().Clustered().Filter("name IS NOT NULL"));
		final idx = Assert.single(tableBuilder.Build().Indexes);
		Assert.isTrue(idx.IsUnique);
		Assert.isTrue(idx.IsClustered);
		Assert.equals("name IS NOT NULL", idx.FilterExpression);
	}

	// ---- SqlExpression Conversion Tests ----

	function testToCreateTableExpression_ConvertsColumnsCorrectly() {
		final builder = new DatabaseBuilder();
		final tableBuilder = builder.AddTable(DtbTestEntity, "TestEntities");
		tableBuilder.Property(e -> e.id);
		tableBuilder.Property(e -> e.stringValue);
		tableBuilder.Property(e -> e.decimalValue);
		tableBuilder.Property(e -> e.guidValue);
		tableBuilder.Build();

		final expr = builder.ToCreateTableExpressions()[0];

		Assert.equals("TestEntities", expr.TableName);
		Assert.equals(4, expr.Columns.length);

		final idCol = expr.Columns.first(c -> c.Name == "id");
		Assert.equals(SqlInt, idCol.Type);

		final stringCol = expr.Columns.first(c -> c.Name == "stringValue");
		Assert.equals(SqlText, stringCol.Type);
		Assert.isNull(stringCol.MaxLength);

		final decimalCol = expr.Columns.first(c -> c.Name == "decimalValue");
		Assert.isTrue(decimalCol.Type.match(SqlDecimal(_, _)));
		Assert.equals(18, decimalCol.Precision);
		Assert.equals(2, decimalCol.Scale);

		final guidCol = expr.Columns.first(c -> c.Name == "guidValue");
		Assert.equals(SqlGuid, guidCol.Type);
	}

	function testToCreateTableExpression_ConvertsPrimaryKeyConstraint() {
		final builder = new DatabaseBuilder();
		final tableBuilder = builder.AddTable(DtbTestEntity);
		tableBuilder.Property(e -> e.id);
		tableBuilder.HasPrimaryKey("PK_Test", e -> e.id);
		tableBuilder.Build();

		final expr = builder.ToCreateTableExpressions()[0];

		final pk = Assert.single(expr.Constraints.ofType(PrimaryKeyConstraint));
		Assert.equals("PK_Test", pk.Name);
		Assert.equals("id", pk.Columns[0]);
	}

	function testToCreateTableExpression_ConvertsForeignKeyConstraint() {
		final builder = new DatabaseBuilder();
		final parentTable = builder.AddTable(DtbParentEntity, "Parents");
		parentTable.Property(p -> p.id);
		parentTable.Build();

		final childTable = builder.AddTable(DtbChildEntity, "Children");
		childTable.Property(c -> c.parentId);
		childTable.HasForeignKey(DtbParentEntity, c -> c.parentId, p -> p.id, DatabaseForeignKeyAction.Cascade, DatabaseForeignKeyAction.SetNull);
		childTable.Build();

		final expr = builder.ToCreateTableExpressions().first(e -> e.TableName == "Children");

		final fk = Assert.single(expr.Constraints.ofType(ForeignKeyConstraint));
		Assert.equals("Parents", fk.ReferencedTable);
		Assert.equals(ForeignKeyAction.Cascade, fk.OnDelete);
		Assert.equals(ForeignKeyAction.SetNull, fk.OnUpdate);
	}

	function testToCreateTableExpression_ConvertsUniqueConstraint() {
		final builder = new DatabaseBuilder();
		final tableBuilder = builder.AddTable(DtbParentEntity);
		tableBuilder.Property(p -> p.name);
		tableBuilder.HasUnique("UQ_Test", p -> p.name);
		tableBuilder.Build();

		final expr = builder.ToCreateTableExpressions()[0];

		final uq = Assert.single(expr.Constraints.ofType(UniqueConstraint));
		Assert.equals("UQ_Test", uq.Name);
		Assert.equals("name", uq.Columns[0]);
	}

	function testToSchemaExpressions_IncludesCreateIndexExpressions() {
		final builder = new DatabaseBuilder();
		final tableBuilder = builder.AddTable(DtbParentEntity, "Parents");
		tableBuilder.Property(p -> p.name);
		tableBuilder.HasIndex("IX_Parents_Name", idx -> idx.Descending("name").Unique());
		tableBuilder.Build();

		final expressions = builder.ToSchemaExpressions();

		Assert.equals(2, expressions.length);

		final createIndex = expressions.ofType(CreateIndexExpression).single();
		Assert.equals("IX_Parents_Name", createIndex.IndexName);
		Assert.equals("Parents", createIndex.TableName);
		Assert.isTrue(createIndex.IsUnique);
		Assert.isTrue(createIndex.Columns[0].Descending);
	}

	// ---- Multiple Tables Configuration ----

	function testDatabaseBuilder_ConfiguresMultipleTablesWithRelationships() {
		final builder = new DatabaseBuilder();

		final parent = builder.AddTable(DtbParentEntity, "Parents");
		parent.Property(p -> p.id);
		parent.Property(p -> p.name);
		parent.HasPrimaryKey(p -> p.id);
		parent.HasUnique(p -> p.name);
		parent.Build();

		final child = builder.AddTable(DtbChildEntity, "Children");
		child.Property(c -> c.id);
		child.Property(c -> c.parentId);
		child.Property(c -> c.description);
		child.HasPrimaryKey(c -> c.id);
		child.HasForeignKey(DtbParentEntity, c -> c.parentId, p -> p.id, DatabaseForeignKeyAction.Cascade);
		child.HasIndex(c -> c.parentId);
		child.Build();

		final expressions = builder.ToSchemaExpressions();

		// 2 CREATE TABLE + 1 CREATE INDEX
		Assert.equals(3, expressions.length);

		final parentExpr = expressions.ofType(CreateTableExpression).first(e -> e.TableName == "Parents");
		Assert.single(parentExpr.Constraints.ofType(PrimaryKeyConstraint));
		Assert.single(parentExpr.Constraints.ofType(UniqueConstraint));

		final childExpr = expressions.ofType(CreateTableExpression).first(e -> e.TableName == "Children");
		Assert.single(childExpr.Constraints.ofType(PrimaryKeyConstraint));
		Assert.single(childExpr.Constraints.ofType(ForeignKeyConstraint));

		final indexExpr = expressions.ofType(CreateIndexExpression).single();
		Assert.equals("Children", indexExpr.TableName);
	}
}

private class DtbTestEntity {
	public var id:Int = 0;
	public var nullableInt:Null<Int>;
	public var bigId:haxe.Int64;
	public var nullableLong:Null<haxe.Int64>;
	public var smallNumber:SmallInt = 0;
	public var nullableShort:Null<SmallInt>;
	public var tinyNumber:TinyInt = 0;
	public var nullableByte:Null<TinyInt>;
	public var floatValue:Single = 0;
	public var nullableFloat:Null<Single>;
	public var doubleValue:Float = 0;
	public var nullableDouble:Null<Float>;
	public var decimalValue:Decimal = 0;
	public var nullableDecimal:Null<Decimal>;
	public var stringValue:String = "";
	public var boolValue:Bool = false;
	public var nullableBool:Null<Bool>;
	public var dateTimeValue:Date;
	public var nullableDateTime:Null<Date>;
	public var dateTimeOffsetValue:DateTimeOffset;
	public var nullableDateTimeOffset:Null<DateTimeOffset>;
	public var timeSpanValue:TimeSpan = 0;
	public var nullableTimeSpan:Null<TimeSpan>;
	public var guidValue:Guid;
	public var nullableGuid:Null<Guid>;
	public var binaryValue:haxe.io.Bytes;

	public function new() {}
}

private class DtbParentEntity {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

private class DtbChildEntity {
	public var id:Int = 0;
	public var parentId:Int = 0;
	public var description:String = "";

	public function new() {}
}

private class DtbCompositeKeyEntity {
	public var key1:Int = 0;
	public var key2:Int = 0;
	public var value:String = "";

	public function new() {}
}
