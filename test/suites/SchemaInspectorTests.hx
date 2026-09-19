package suites;

import codequery.Decimal;
import codequery.Guid;
import codequery.inspection.SchemaInspector;
import codequery.migrations.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/** `SchemaInspectorTests.cs`. */
class SchemaInspectorTests extends TestCase {
	// ---- Basic Type Inspection ----

	function testFromType_SimpleClass_CreatesDefinition() {
		final definition = SchemaInspector.FromType(SiSimpleEntity);
		Assert.equals("SiSimpleEntity", definition.TableName);
		Assert.equals(2, definition.Columns.length);
	}

	function testFromType_DetectsIdAsPrimaryKey() {
		final definition = SchemaInspector.FromType(SiSimpleEntity);
		final pk = Assert.single(definition.Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals("id", pk.Columns[0]);
	}

	function testFromType_IntPrimaryKeyIsAutoIncrement() {
		final definition = SchemaInspector.FromType(SiSimpleEntity);
		final idColumn = definition.Columns.first(c -> c.Name == "id");
		Assert.isTrue(idColumn.IsAutoIncrement);
	}

	// ---- Table Attribute ----

	function testFromType_TableAttribute_UsesCustomName() {
		final definition = SchemaInspector.FromType(SiEntityWithTableAttribute);
		Assert.equals("CustomTableName", definition.TableName);
	}

	function testFromType_TableAttribute_UsesSchema() {
		final definition = SchemaInspector.FromType(SiEntityWithTableAttribute);
		Assert.equals("dbo", definition.Schema);
	}

	// ---- Column Types ----

	function testFromType_MapsIntToInt() {
		final column = SchemaInspector.FromType(SiAllTypesEntity).Columns.first(c -> c.Name == "intValue");
		Assert.equals(DatabaseColumnType.Int, column.Type);
	}

	function testFromType_MapsLongToBigInt() {
		final column = SchemaInspector.FromType(SiAllTypesEntity).Columns.first(c -> c.Name == "longValue");
		Assert.equals(DatabaseColumnType.BigInt, column.Type);
	}

	function testFromType_MapsStringToVarChar() {
		final column = SchemaInspector.FromType(SiAllTypesEntity).Columns.first(c -> c.Name == "stringValue");
		Assert.equals(DatabaseColumnType.VarChar, column.Type);
	}

	function testFromType_MapsDecimalToDecimal() {
		final column = SchemaInspector.FromType(SiAllTypesEntity).Columns.first(c -> c.Name == "decimalValue");
		Assert.equals(DatabaseColumnType.Decimal, column.Type);
	}

	function testFromType_MapsDateTimeToDateTime() {
		final column = SchemaInspector.FromType(SiAllTypesEntity).Columns.first(c -> c.Name == "dateTimeValue");
		Assert.equals(DatabaseColumnType.DateTime, column.Type);
	}

	function testFromType_MapsBoolToBoolean() {
		final column = SchemaInspector.FromType(SiAllTypesEntity).Columns.first(c -> c.Name == "boolValue");
		Assert.equals(DatabaseColumnType.Boolean, column.Type);
	}

	function testFromType_MapsGuidToGuid() {
		final column = SchemaInspector.FromType(SiAllTypesEntity).Columns.first(c -> c.Name == "guidValue");
		Assert.equals(DatabaseColumnType.Guid, column.Type);
	}

	function testFromType_MapsByteArrayToVarBinary() {
		final column = SchemaInspector.FromType(SiAllTypesEntity).Columns.first(c -> c.Name == "byteArrayValue");
		Assert.equals(DatabaseColumnType.VarBinary, column.Type);
	}

	function testFromType_MapsEnumToInt() {
		final column = SchemaInspector.FromType(SiAllTypesEntity).Columns.first(c -> c.Name == "enumValue");
		Assert.equals(DatabaseColumnType.Int, column.Type);
	}

	// ---- Nullability ----

	function testFromType_ValueType_NotNullable() {
		final column = SchemaInspector.FromType(SiNullabilityEntity).Columns.first(c -> c.Name == "nonNullableInt");
		Assert.isFalse(column.IsNullable);
	}

	function testFromType_NullableValueType_IsNullable() {
		final column = SchemaInspector.FromType(SiNullabilityEntity).Columns.first(c -> c.Name == "nullableInt");
		Assert.isTrue(column.IsNullable);
	}

	function testFromType_ReferenceType_IsNullable() {
		final column = SchemaInspector.FromType(SiNullabilityEntity).Columns.first(c -> c.Name == "nullableString");
		Assert.isTrue(column.IsNullable);
	}

	function testFromType_RequiredAttribute_NotNullable() {
		final column = SchemaInspector.FromType(SiNullabilityEntity).Columns.first(c -> c.Name == "requiredString");
		Assert.isFalse(column.IsNullable);
	}

	// ---- MaxLength ----

	function testFromType_StringWithoutMaxLength_IsUnbounded() {
		final column = SchemaInspector.FromType(SiSimpleEntity).Columns.first(c -> c.Name == "name");
		Assert.isNull(column.MaxLength);
	}

	function testFromType_MaxLengthAttribute_SetsMaxLength() {
		final column = SchemaInspector.FromType(SiMaxLengthEntity).Columns.first(c -> c.Name == "limitedString");
		Assert.equals(100, column.MaxLength);
	}

	function testFromType_StringLengthAttribute_SetsMaxLength() {
		final column = SchemaInspector.FromType(SiMaxLengthEntity).Columns.first(c -> c.Name == "stringLengthString");
		Assert.equals(50, column.MaxLength);
	}

	// ---- Column Attribute ----

	function testFromType_ColumnAttribute_UsesCustomName() {
		final column = SchemaInspector.FromType(SiColumnAttributeEntity).Columns.firstOrDefault(c -> c.Name == "custom_column_name");
		Assert.notNull(column);
	}

	function testFromType_Precision_IsSaidInNumbers() {
		final column = SchemaInspector.FromType(SiColumnAttributeEntity).Columns.first(c -> c.Name == "amount");
		Assert.equals(10, column.Precision);
		Assert.equals(4, column.Scale);
	}

	/** A dialect's own type name belongs to that dialect, so it is refused rather than read. */
	function testFromType_ColumnTypeName_IsRefused() {
		final error = Assert.throwsMessage(() -> SchemaInspector.FromType(SiNamedTypeEntity));
		Assert.contains("decimal(18,2)", error);
		Assert.contains("DbColumnPrecision", error);
	}

	// ---- Key Attribute ----

	function testFromType_KeyAttribute_SetsPrimaryKey() {
		final definition = SchemaInspector.FromType(SiExplicitKeyEntity);
		final pk = Assert.single(definition.Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals("customKey", pk.Columns[0]);
	}

	function testFromType_NoAutoIncrement_WhenNotIntOrLong() {
		final idColumn = SchemaInspector.FromType(SiGuidKeyEntity).Columns.first(c -> c.Name == "id");
		Assert.isFalse(idColumn.IsAutoIncrement);
	}

	// ---- NotMapped Attribute ----

	function testFromType_NotMappedAttribute_ExcludesProperty() {
		final definition = SchemaInspector.FromType(SiNotMappedEntity);
		Assert.isFalse(definition.Columns.any(c -> c.Name == "notMappedProperty"));
		Assert.isTrue(definition.Columns.any(c -> c.Name == "mappedProperty"));
	}

	// ---- Navigation Properties ----

	function testFromType_SkipsNavigationProperties() {
		final definition = SchemaInspector.FromType(SiEntityWithNavigation);
		Assert.isFalse(definition.Columns.any(c -> c.Name == "relatedEntity"));
		Assert.isFalse(definition.Columns.any(c -> c.Name == "relatedEntities"));
	}

	function testFromType_IncludesForeignKeyProperty() {
		final definition = SchemaInspector.FromType(SiEntityWithNavigation);
		Assert.isTrue(definition.Columns.any(c -> c.Name == "relatedEntityId"));
	}

	// ---- DatabaseGenerated Attribute ----

	function testFromType_DatabaseGeneratedIdentity_IsAutoIncrement() {
		final column = SchemaInspector.FromType(SiDatabaseGeneratedEntity).Columns.first(c -> c.Name == "sequenceNumber");
		Assert.isTrue(column.IsAutoIncrement);
	}

	// ---- FromTypes ----

	function testFromTypes_ReturnsMultipleDefinitions() {
		final definitions = SchemaInspector.FromTypes(SiSimpleEntity, SiExplicitKeyEntity);
		Assert.equals(2, definitions.length);
		Assert.isTrue(definitions.any(d -> d.TableName == "SiSimpleEntity"));
		Assert.isTrue(definitions.any(d -> d.TableName == "SiExplicitKeyEntity"));
	}
}

private class SiSimpleEntity {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

@tableName("CustomTableName", "dbo")
private class SiEntityWithTableAttribute {
	public var id:Int = 0;

	public function new() {}
}

private enum abstract SiTestEnum(Int) {
	var Value1 = 0;
	var Value2 = 1;
}

private class SiAllTypesEntity {
	public var id:Int = 0;
	public var intValue:Int = 0;
	public var longValue:haxe.Int64;
	public var stringValue:String = "";
	public var decimalValue:Decimal = 0;
	public var dateTimeValue:Date;
	public var boolValue:Bool = false;
	public var guidValue:Guid;
	public var byteArrayValue:haxe.io.Bytes;
	public var enumValue:SiTestEnum;

	public function new() {}
}

private class SiNullabilityEntity {
	public var id:Int = 0;
	public var nonNullableInt:Int = 0;
	public var nullableInt:Null<Int>;
	public var nullableString:Null<String>;
	@required
	public var requiredString:String = "";

	public function new() {}
}

private class SiMaxLengthEntity {
	public var id:Int = 0;
	@maxLength(100)
	public var limitedString:String = "";
	@stringLength(50)
	public var stringLengthString:String = "";

	public function new() {}
}

private class SiColumnAttributeEntity {
	public var id:Int = 0;
	@column("custom_column_name")
	public var customName:String = "";
	@dbColumnPrecision(10, 4)
	public var amount:Decimal = 0;

	public function new() {}
}

private class SiNamedTypeEntity {
	public var id:Int = 0;
	@columnTypeName("decimal(18,2)")
	public var amount:Decimal = 0;

	public function new() {}
}

private class SiExplicitKeyEntity {
	@key
	public var customKey:String = "";
	public var name:String = "";

	public function new() {}
}

private class SiGuidKeyEntity {
	public var id:Guid;
	public var name:String = "";

	public function new() {}
}

private class SiNotMappedEntity {
	public var id:Int = 0;
	public var mappedProperty:String = "";
	@notMapped
	public var notMappedProperty:String = "";

	public function new() {}
}

private class SiEntityWithNavigation {
	public var id:Int = 0;
	public var relatedEntityId:Int = 0;
	public var relatedEntity:Null<SiSimpleEntity>;
	public var relatedEntities:Null<Array<SiSimpleEntity>>;

	public function new() {}
}

private class SiDatabaseGeneratedEntity {
	public var id:Int = 0;
	@databaseGenerated("Identity")
	public var sequenceNumber:haxe.Int64;

	public function new() {}
}
