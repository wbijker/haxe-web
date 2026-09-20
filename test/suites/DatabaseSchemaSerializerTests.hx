package suites;

import codequery.migrations.*;
import codequery.schemabuilder.TableBuilder;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/** `DatabaseSchemaSerializerTests.cs`. */
class DatabaseSchemaSerializerTests extends TestCase {
	// ---- Basic Serialization ----

	function testSerialize_EmptySchema_ProducesValidJson() {
		final schema = new DatabaseSchema("TestSchema");

		final json = DatabaseSchemaSerializer.Serialize(schema);

		Assert.contains('"name":', json);
		Assert.contains('"TestSchema"', json);
		Assert.contains('"tables":', json);
	}

	function testSerialize_SchemaWithMetadata_IncludesAllFields() {
		final schema = new DatabaseSchema();
		schema.Name = "ProductionSchema";
		schema.Version = 2;
		schema.Description = "Production database schema";
		schema.Provider = "PostgreSQL";
		schema.CreatedAt = new Date(2024, 0, 15, 10, 30, 0);

		final json = DatabaseSchemaSerializer.Serialize(schema);

		Assert.contains('"version": 2', json);
		Assert.contains('"description":', json);
		Assert.contains('"provider":', json);
		Assert.contains('"createdAt":', json);
	}

	function testDeserialize_ValidJson_ReturnsSchema() {
		final json = '{
			"name": "TestSchema",
			"version": 1,
			"tables": []
		}';

		final schema = DatabaseSchemaSerializer.Deserialize(json);

		Assert.equals("TestSchema", schema.Name);
		Assert.equals(1, schema.Version);
		Assert.empty(schema.Tables);
	}

	// ---- Table Serialization ----

	function testSerialize_TableWithColumns_IncludesColumnDetails() {
		final table = TableBuilder.Create().Table("Users")
			.Int("Id", c -> c.Identity())
			.String("Name", c -> c.MaxLength(100).NotNull())
			.String("Email", c -> c.MaxLength(200).Nullable())
			.DateTime("CreatedAt")
			.Build();

		final schema = DatabaseSchema.FromTables([table]);
		final json = DatabaseSchemaSerializer.Serialize(schema);

		Assert.contains('"tableName": "Users"', json);
		Assert.contains('"name": "Id"', json);
		Assert.contains('"name": "Name"', json);
		Assert.contains('"name": "Email"', json);
		Assert.contains('"maxLength": 100', json);
		Assert.contains('"isNullable": true', json);
		Assert.contains('"isNullable": false', json);
	}

	function testSerializeDeserialize_TableWithColumns_RoundTrip() {
		final table = TableBuilder.Create().Table("Products")
			.Int("Id", c -> c.Identity())
			.String("Name", c -> c.MaxLength(200).NotNull())
			.Decimal("Price", c -> c.Precision(18, 2))
			.Boolean("IsActive")
			.Build();

		final schema = DatabaseSchema.FromTables([table], "ProductSchema");
		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		Assert.equals("ProductSchema", deserialized.Name);
		Assert.single(deserialized.Tables);

		final deserializedTable = deserialized.Tables[0];
		Assert.equals("Products", deserializedTable.TableName);
		Assert.equals(4, deserializedTable.Columns.length);

		final nameCol = deserializedTable.Columns.firstOrDefault(c -> c.Name == "Name");
		Assert.notNull(nameCol);
		Assert.equals(200, nameCol.MaxLength);
		Assert.isFalse(nameCol.IsNullable);

		final priceCol = deserializedTable.Columns.firstOrDefault(c -> c.Name == "Price");
		Assert.notNull(priceCol);
		Assert.equals(18, priceCol.Precision);
		Assert.equals(2, priceCol.Scale);
	}

	function testSerialize_Columns_IncludesOrdinalIndex() {
		final table = TableBuilder.Create().Table("Users").Int("Id").String("Name").String("Email").Build();

		final schema = DatabaseSchema.FromTables([table]);
		final json = DatabaseSchemaSerializer.Serialize(schema);

		Assert.contains('"ordinalIndex": 0', json);
		Assert.contains('"ordinalIndex": 1', json);
		Assert.contains('"ordinalIndex": 2', json);
	}

	function testSerializeDeserialize_OrdinalIndex_RoundTrip() {
		final table = TableBuilder.Create().Table("Users").Int("Id").String("Name").String("Email").Build();

		final schema = DatabaseSchema.FromTables([table]);
		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		final cols = deserialized.Tables[0].Columns;
		Assert.equals(0, cols[0].OrdinalIndex);
		Assert.equals(1, cols[1].OrdinalIndex);
		Assert.equals(2, cols[2].OrdinalIndex);
	}

	function testDeserialize_LegacySnapshotWithoutOrdinal_LeavesOrdinalNull() {
		final json = '{
			"tableName": "Users",
			"columns": [
				{ "name": "Id", "type": "int", "isNullable": false },
				{ "name": "Name", "type": "varChar", "maxLength": 100 }
			],
			"constraints": [],
			"indexes": []
		}';

		final table = DatabaseSchemaSerializer.DeserializeTable(json);

		for (c in table.Columns) {
			Assert.isNull(c.OrdinalIndex);
		}
	}

	// ---- Constraint Serialization ----

	function testSerializeDeserialize_PrimaryKeyConstraint_RoundTrip() {
		final table = TableBuilder.Create().Table("Users").Int("Id").String("TenantId").PrimaryKey("PK_Users", ["Id", "TenantId"]).Build();

		final schema = DatabaseSchema.FromTables([table]);
		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		final pk = deserialized.Tables[0].Constraints.ofType(DatabasePrimaryKeyConstraint).single();

		Assert.equals("PK_Users", pk.Name);
		Assert.equals(["Id", "TenantId"], pk.Columns);
	}

	function testSerializeDeserialize_ForeignKeyConstraint_RoundTrip() {
		final schema = new DatabaseSchema("TestSchema");
		final table = new DatabaseTableDefinition("Orders");
		table.Columns = [
			new DatabaseColumnDefinition("Id", DatabaseColumnType.Int),
			new DatabaseColumnDefinition("UserId", DatabaseColumnType.Int)
		];
		table.Constraints = [
			new DatabaseForeignKeyConstraint("FK_Orders_Users", ["UserId"], "Users", ["Id"],
				DatabaseForeignKeyAction.Cascade, DatabaseForeignKeyAction.NoAction)
		];
		schema.AddTable(table);

		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		final fk = deserialized.Tables[0].Constraints.ofType(DatabaseForeignKeyConstraint).single();

		Assert.equals("FK_Orders_Users", fk.Name);
		Assert.equals(["UserId"], fk.Columns);
		Assert.equals("Users", fk.ReferencedTable);
		Assert.equals(["Id"], fk.ReferencedColumns);
		Assert.equals(DatabaseForeignKeyAction.Cascade, fk.OnDelete);
		Assert.equals(DatabaseForeignKeyAction.NoAction, fk.OnUpdate);
	}

	function testSerializeDeserialize_UniqueConstraint_RoundTrip() {
		final table = TableBuilder.Create().Table("Users").Int("Id").String("Email").Unique("UQ_Users_Email", ["Email"]).Build();

		final schema = DatabaseSchema.FromTables([table]);
		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		final uq = deserialized.Tables[0].Constraints.ofType(DatabaseUniqueConstraint).single();

		Assert.equals("UQ_Users_Email", uq.Name);
		Assert.equals(["Email"], uq.Columns);
	}

	function testSerializeDeserialize_CheckConstraint_RoundTrip() {
		final table = TableBuilder.Create().Table("Products").Int("Id").Decimal("Price").Check("CK_Products_Price", "Price > 0").Build();

		final schema = DatabaseSchema.FromTables([table]);
		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		final ck = deserialized.Tables[0].Constraints.ofType(DatabaseCheckConstraint).single();

		Assert.equals("CK_Products_Price", ck.Name);
		Assert.equals("Price > 0", ck.Expression);
	}

	function testSerializeDeserialize_MultipleConstraintTypes_RoundTrip() {
		final schema = new DatabaseSchema("TestSchema");
		final table = new DatabaseTableDefinition("Orders");
		table.Columns = [
			new DatabaseColumnDefinition("Id", DatabaseColumnType.Int),
			new DatabaseColumnDefinition("OrderNumber", DatabaseColumnType.VarChar, true, {maxLength: 50}),
			new DatabaseColumnDefinition("UserId", DatabaseColumnType.Int),
			new DatabaseColumnDefinition("Total", DatabaseColumnType.Decimal)
		];
		table.Constraints = [
			new DatabasePrimaryKeyConstraint("PK_Orders", ["Id"]),
			new DatabaseUniqueConstraint("UQ_Orders_Number", ["OrderNumber"]),
			new DatabaseForeignKeyConstraint("FK_Orders_Users", ["UserId"], "Users", ["Id"]),
			new DatabaseCheckConstraint("CK_Orders_Total", "Total >= 0")
		];
		schema.AddTable(table);

		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		Assert.equals(4, deserialized.Tables[0].Constraints.length);
		Assert.single(deserialized.Tables[0].Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.single(deserialized.Tables[0].Constraints.ofType(DatabaseUniqueConstraint));
		Assert.single(deserialized.Tables[0].Constraints.ofType(DatabaseForeignKeyConstraint));
		Assert.single(deserialized.Tables[0].Constraints.ofType(DatabaseCheckConstraint));
	}

	// ---- Index Serialization ----

	function testSerializeDeserialize_Index_RoundTrip() {
		final table = TableBuilder.Create().Table("Users").Int("Id").String("LastName").String("FirstName")
			.Index("IX_Users_Name", idx -> idx.Column("LastName").Column("FirstName", DatabaseSortOrder.Descending))
			.Build();

		final schema = DatabaseSchema.FromTables([table]);
		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		final idx = deserialized.Tables[0].Indexes.single();

		Assert.equals("IX_Users_Name", idx.Name);
		Assert.equals(2, idx.Columns.length);
		Assert.equals("LastName", idx.Columns[0].ColumnName);
		Assert.equals(DatabaseSortOrder.Ascending, idx.Columns[0].SortOrder);
		Assert.equals("FirstName", idx.Columns[1].ColumnName);
		Assert.equals(DatabaseSortOrder.Descending, idx.Columns[1].SortOrder);
	}

	function testSerializeDeserialize_UniqueIndex_RoundTrip() {
		final table = TableBuilder.Create().Table("Users").Int("Id").String("Email")
			.Index("IX_Users_Email", idx -> idx.Column("Email").Unique()).Build();

		final schema = DatabaseSchema.FromTables([table]);
		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		final idx = deserialized.Tables[0].Indexes.single();

		Assert.equals("IX_Users_Email", idx.Name);
		Assert.isTrue(idx.IsUnique);
	}

	function testSerializeDeserialize_FilteredIndex_RoundTrip() {
		final schema = new DatabaseSchema();
		final table = new DatabaseTableDefinition("Users");
		table.Columns = [
			new DatabaseColumnDefinition("Id", DatabaseColumnType.Int),
			new DatabaseColumnDefinition("Email", DatabaseColumnType.VarChar),
			new DatabaseColumnDefinition("IsActive", DatabaseColumnType.Boolean)
		];
		table.Indexes = [
			new DatabaseIndexDefinition("IX_Users_Email_Active", [new DatabaseIndexColumn("Email")], true, false, "IsActive = 1")
		];
		schema.AddTable(table);

		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		final idx = deserialized.Tables[0].Indexes.single();

		Assert.equals("IX_Users_Email_Active", idx.Name);
		Assert.equals("IsActive = 1", idx.FilterExpression);
	}

	// ---- Complete Schema Round-Trip ----

	function testSerializeDeserialize_CompleteSchema_RoundTrip() {
		final users = TableBuilder.Create().Table("Users").Schema("dbo")
			.Int("Id", c -> c.Identity())
			.String("Email", c -> c.MaxLength(200).NotNull())
			.String("Name", c -> c.MaxLength(100))
			.DateTime("CreatedAt")
			.Boolean("IsActive")
			.PrimaryKey("PK_Users", ["Id"])
			.Unique("UQ_Users_Email", ["Email"])
			.Index("IX_Users_Name", ["Name"])
			.Build();

		final orders = TableBuilder.Create().Table("Orders").Schema("dbo")
			.Int("Id", c -> c.Identity())
			.Int("UserId")
			.Decimal("Total", c -> c.Precision(18, 2))
			.DateTime("OrderDate")
			.PrimaryKey("PK_Orders", ["Id"])
			.Check("CK_Orders_Total", "Total >= 0")
			.Index("IX_Orders_UserId", ["UserId"])
			.Index("IX_Orders_Date", idx -> idx.Column("OrderDate", DatabaseSortOrder.Descending))
			.Build();

		orders.Constraints.push(new DatabaseForeignKeyConstraint("FK_Orders_Users", ["UserId"], "Users", ["Id"],
			DatabaseForeignKeyAction.Cascade, null, "dbo"));

		final schema = new DatabaseSchema();
		schema.Name = "ECommerceDB";
		schema.Version = 1;
		schema.Description = "E-commerce database schema";
		schema.Provider = "SqlServer";
		schema.CreatedAt = Date.now();
		schema.Tables = [users, orders];

		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		Assert.equals("ECommerceDB", deserialized.Name);
		Assert.equals(1, deserialized.Version);
		Assert.equals("E-commerce database schema", deserialized.Description);
		Assert.equals("SqlServer", deserialized.Provider);
		Assert.equals(2, deserialized.Tables.length);

		final usersTable = deserialized.GetTable("Users", "dbo");
		Assert.notNull(usersTable);
		Assert.equals(5, usersTable.Columns.length);
		Assert.equals(2, usersTable.Constraints.length);
		Assert.single(usersTable.Indexes);

		final ordersTable = deserialized.GetTable("Orders", "dbo");
		Assert.notNull(ordersTable);
		Assert.equals(4, ordersTable.Columns.length);
		Assert.equals(3, ordersTable.Constraints.length);
		Assert.equals(2, ordersTable.Indexes.length);

		final fk = ordersTable.Constraints.ofType(DatabaseForeignKeyConstraint).single();
		Assert.equals("FK_Orders_Users", fk.Name);
		Assert.equals("dbo", fk.ReferencedSchema);
		Assert.equals(DatabaseForeignKeyAction.Cascade, fk.OnDelete);
	}

	// ---- Table Definition Serialization ----

	function testSerializeTable_SingleTable_ProducesValidJson() {
		final table = TableBuilder.Create().Table("Products").Int("Id").String("Name").Build();

		final json = DatabaseSchemaSerializer.SerializeTable(table);

		Assert.contains('"tableName": "Products"', json);
		Assert.contains('"columns":', json);
	}

	function testDeserializeTable_ValidJson_ReturnsTable() {
		final json = '{
			"tableName": "Products",
			"columns": [
				{ "name": "Id", "type": "int", "isNullable": false },
				{ "name": "Name", "type": "varChar", "maxLength": 100 }
			],
			"constraints": [],
			"indexes": []
		}';

		final table = DatabaseSchemaSerializer.DeserializeTable(json);

		Assert.equals("Products", table.TableName);
		Assert.equals(2, table.Columns.length);
	}

	// ---- File Operations ----

	function testSaveToFile_LoadFromFile_RoundTrip() {
		final tempFile = haxe.io.Path.join([Sys.getCwd(), "bin", 'schema-${Std.random(0x7fffffff)}.json']);
		if (!sys.FileSystem.exists("bin")) {
			sys.FileSystem.createDirectory("bin");
		}
		try {
			final table = TableBuilder.Create().Table("TestTable").Int("Id").String("Name").Build();
			final schema = new DatabaseSchema("FileTest");
			schema.Tables = [table];

			DatabaseSchemaSerializer.SaveToFile(schema, tempFile);
			final loaded = DatabaseSchemaSerializer.LoadFromFile(tempFile);

			Assert.equals("FileTest", loaded.Name);
			Assert.single(loaded.Tables);
			Assert.equals("TestTable", loaded.Tables[0].TableName);
			sys.FileSystem.deleteFile(tempFile);
		} catch (e:Dynamic) {
			if (sys.FileSystem.exists(tempFile)) {
				sys.FileSystem.deleteFile(tempFile);
			}
			throw e;
		}
	}

	// ---- Stream Operations ----

	function testSerialize_ToStream_ProducesValidJson() {
		final table = TableBuilder.Create().Table("StreamTest").Int("Id").Build();
		final schema = DatabaseSchema.FromTables([table]);

		final stream = new haxe.io.BytesOutput();
		DatabaseSchemaSerializer.SerializeTo(schema, stream);

		final json = stream.getBytes().toString();
		Assert.contains('"StreamTest"', json);
	}

	function testDeserialize_FromStream_ReturnsSchema() {
		final json = '{
			"name": "StreamSchema",
			"tables": []
		}';

		final stream = new haxe.io.BytesInput(haxe.io.Bytes.ofString(json));
		final schema = DatabaseSchemaSerializer.DeserializeFrom(stream);

		Assert.equals("StreamSchema", schema.Name);
	}

	// ---- Schema Diffing ----

	function testDiff_DeserializedSchemas_GeneratesCorrectChanges() {
		final oldSchemaJson = '{
			"name": "OldSchema",
			"tables": [{
				"tableName": "Users",
				"columns": [
					{ "name": "Id", "type": "int", "isNullable": false },
					{ "name": "Name", "type": "varChar", "maxLength": 100 }
				],
				"constraints": [],
				"indexes": []
			}]
		}';

		final newSchemaJson = '{
			"name": "NewSchema",
			"tables": [{
				"tableName": "Users",
				"columns": [
					{ "name": "Id", "type": "int", "isNullable": false },
					{ "name": "Name", "type": "varChar", "maxLength": 100 },
					{ "name": "Email", "type": "varChar", "maxLength": 200 }
				],
				"constraints": [],
				"indexes": []
			}]
		}';

		final oldSchema = DatabaseSchemaSerializer.Deserialize(oldSchemaJson);
		final newSchema = DatabaseSchemaSerializer.Deserialize(newSchemaJson);

		final changes = newSchema.Diff(oldSchema);

		final addColumn = Assert.single(changes.ofType(AddColumnExpression));
		Assert.equals("Email", addColumn.Column.Name);
	}

	// ---- Column Type Serialization ----

	function testSerializeDeserialize_AllColumnTypes_RoundTrip() {
		final table = new DatabaseTableDefinition("AllTypes");
		table.Columns = [
			new DatabaseColumnDefinition("BoolCol", DatabaseColumnType.Boolean),
			new DatabaseColumnDefinition("TinyIntCol", DatabaseColumnType.TinyInt),
			new DatabaseColumnDefinition("SmallIntCol", DatabaseColumnType.SmallInt),
			new DatabaseColumnDefinition("IntCol", DatabaseColumnType.Int),
			new DatabaseColumnDefinition("BigIntCol", DatabaseColumnType.BigInt),
			new DatabaseColumnDefinition("FloatCol", DatabaseColumnType.Float),
			new DatabaseColumnDefinition("DoubleCol", DatabaseColumnType.Double),
			new DatabaseColumnDefinition("DecimalCol", DatabaseColumnType.Decimal, true, {precision: 18, scale: 4}),
			new DatabaseColumnDefinition("CharCol", DatabaseColumnType.Char),
			new DatabaseColumnDefinition("VarCharCol", DatabaseColumnType.VarChar, true, {maxLength: 255}),
			new DatabaseColumnDefinition("TextCol", DatabaseColumnType.Text),
			new DatabaseColumnDefinition("DateCol", DatabaseColumnType.Date),
			new DatabaseColumnDefinition("TimeCol", DatabaseColumnType.Time),
			new DatabaseColumnDefinition("DateTimeCol", DatabaseColumnType.DateTime),
			new DatabaseColumnDefinition("GuidCol", DatabaseColumnType.Guid),
			new DatabaseColumnDefinition("BinaryCol", DatabaseColumnType.Binary),
			new DatabaseColumnDefinition("JsonCol", DatabaseColumnType.Json),
			new DatabaseColumnDefinition("XmlCol", DatabaseColumnType.Xml)
		];

		final schema = DatabaseSchema.FromTables([table]);
		final json = DatabaseSchemaSerializer.Serialize(schema);
		final deserialized = DatabaseSchemaSerializer.Deserialize(json);

		Assert.equals(18, deserialized.Tables[0].Columns.length);

		final decimalCol = deserialized.Tables[0].Columns.firstOrDefault(c -> c.Name == "DecimalCol");
		Assert.notNull(decimalCol);
		Assert.equals(DatabaseColumnType.Decimal, decimalCol.Type);
		Assert.equals(18, decimalCol.Precision);
		Assert.equals(4, decimalCol.Scale);

		final varCharCol = deserialized.Tables[0].Columns.firstOrDefault(c -> c.Name == "VarCharCol");
		Assert.notNull(varCharCol);
		Assert.equals(DatabaseColumnType.VarChar, varCharCol.Type);
		Assert.equals(255, varCharCol.MaxLength);
	}
}
