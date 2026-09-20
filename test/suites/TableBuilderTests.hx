package suites;

import codequery.migrations.*;
import codequery.schemabuilder.TableBuilder;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.Author;
import entities.Book;

using codequery.testing.Linq;
using codequery.testing.TestSchemaHelpers;

/** `TableBuilderTests.cs`. */
class TableBuilderTests extends TestCase {
	// ---- Basic Table Creation ----

	function testSchemaBuilder_CreatesTableWithName() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").Build();
		Assert.equals("Users", definition.TableName);
	}

	function testSchemaBuilder_CreatesTableWithSchema() {
		final definition = TableBuilder.Create().Table("Users").Schema("dbo").Int("Id").Build();
		Assert.equals("dbo", definition.Schema);
	}

	function testSchemaBuilder_ThrowsWithoutTableName() {
		final builder = TableBuilder.Create().Int("Id");
		Assert.throws(() -> builder.Build());
	}

	// ---- String Columns ----

	function testSchemaBuilder_String_IsUnboundedUntilASizeIsGiven() {
		final definition = TableBuilder.Create().Table("Test").String("Name").Build();
		final column = definition.Columns[0];
		Assert.equals("Name", column.Name);
		Assert.equals(DatabaseColumnType.VarChar, column.Type);
		Assert.isNull(column.MaxLength);
	}

	function testSchemaBuilder_String_CustomMaxLength() {
		final definition = TableBuilder.Create().Table("Test").String("Name", c -> c.MaxLength(50)).Build();
		Assert.equals(50, definition.Columns[0].MaxLength);
	}

	function testSchemaBuilder_String_WithDefaultValue() {
		final definition = TableBuilder.Create().Table("Test").String("Status", c -> c.DefaultValue("Active")).Build();
		Assert.equals("Active", definition.Columns[0].DefaultValue);
	}

	function testSchemaBuilder_String_WithCollation() {
		final definition = TableBuilder.Create().Table("Test").String("Name", c -> c.Collation("Latin1_General_CI_AS")).Build();
		Assert.equals("Latin1_General_CI_AS", definition.Columns[0].Collation);
	}

	function testSchemaBuilder_Char_FixedLength() {
		final definition = TableBuilder.Create().Table("Test").Char("Code", 3).Build();
		final column = definition.Columns[0];
		Assert.equals(DatabaseColumnType.Char, column.Type);
		Assert.equals(3, column.MaxLength);
	}

	function testSchemaBuilder_Text_NoMaxLength() {
		final definition = TableBuilder.Create().Table("Test").Text("Content").Build();
		final column = definition.Columns[0];
		Assert.equals(DatabaseColumnType.Text, column.Type);
		Assert.isNull(column.MaxLength);
	}

	// ---- Numeric Columns ----

	function testSchemaBuilder_Int_Basic() {
		final definition = TableBuilder.Create().Table("Test").Int("Count").Build();
		final column = definition.Columns[0];
		Assert.equals(DatabaseColumnType.Int, column.Type);
		Assert.isFalse(column.IsAutoIncrement);
	}

	function testSchemaBuilder_Int_Identity() {
		final definition = TableBuilder.Create().Table("Test").Int("Id", c -> c.Identity()).Build();
		Assert.isTrue(definition.Columns[0].IsAutoIncrement);
	}

	function testSchemaBuilder_Int_DefaultValue() {
		final definition = TableBuilder.Create().Table("Test").Int("Count", c -> c.DefaultValue(0)).Build();
		Assert.equals("0", definition.Columns[0].DefaultValue);
	}

	function testSchemaBuilder_BigInt() {
		final definition = TableBuilder.Create().Table("Test").BigInt("BigNumber", c -> c.Identity()).Build();
		final column = definition.Columns[0];
		Assert.equals(DatabaseColumnType.BigInt, column.Type);
		Assert.isTrue(column.IsAutoIncrement);
	}

	function testSchemaBuilder_SmallInt() {
		final definition = TableBuilder.Create().Table("Test").SmallInt("SmallNumber").Build();
		Assert.equals(DatabaseColumnType.SmallInt, definition.Columns[0].Type);
	}

	function testSchemaBuilder_TinyInt() {
		final definition = TableBuilder.Create().Table("Test").TinyInt("TinyNumber").Build();
		Assert.equals(DatabaseColumnType.TinyInt, definition.Columns[0].Type);
	}

	function testSchemaBuilder_Decimal_DefaultPrecision() {
		final definition = TableBuilder.Create().Table("Test").Decimal("Amount").Build();
		final column = definition.Columns[0];
		Assert.equals(DatabaseColumnType.Decimal, column.Type);
		Assert.equals(18, column.Precision);
		Assert.equals(2, column.Scale);
	}

	function testSchemaBuilder_Decimal_CustomPrecision() {
		final definition = TableBuilder.Create().Table("Test").Decimal("Amount", c -> c.Precision(10, 4)).Build();
		final column = definition.Columns[0];
		Assert.equals(10, column.Precision);
		Assert.equals(4, column.Scale);
	}

	function testSchemaBuilder_Float() {
		final definition = TableBuilder.Create().Table("Test").Float("Rate", c -> c.DefaultValue(1.5)).Build();
		final column = definition.Columns[0];
		Assert.equals(DatabaseColumnType.Float, column.Type);
		Assert.equals("1.5", column.DefaultValue);
	}

	function testSchemaBuilder_Double() {
		final definition = TableBuilder.Create().Table("Test").Double("Precise").Build();
		Assert.equals(DatabaseColumnType.Double, definition.Columns[0].Type);
	}

	// ---- Boolean Column ----

	function testSchemaBuilder_Boolean_Basic() {
		final definition = TableBuilder.Create().Table("Test").Boolean("IsActive").Build();
		Assert.equals(DatabaseColumnType.Boolean, definition.Columns[0].Type);
	}

	function testSchemaBuilder_Boolean_DefaultTrue() {
		final definition = TableBuilder.Create().Table("Test").Boolean("IsActive", c -> c.DefaultValue(true)).Build();
		Assert.equals("true", definition.Columns[0].DefaultValue);
	}

	function testSchemaBuilder_Boolean_DefaultFalse() {
		final definition = TableBuilder.Create().Table("Test").Boolean("IsDeleted", c -> c.DefaultValue(false)).Build();
		Assert.equals("false", definition.Columns[0].DefaultValue);
	}

	// ---- DateTime Columns ----

	function testSchemaBuilder_DateTime_Basic() {
		final definition = TableBuilder.Create().Table("Test").DateTime("CreatedAt").Build();
		Assert.equals(DatabaseColumnType.DateTime, definition.Columns[0].Type);
	}

	function testSchemaBuilder_DateTime_DefaultCurrentTimestamp() {
		final definition = TableBuilder.Create().Table("Test").DateTime("CreatedAt", c -> c.DefaultCurrentTimestamp()).Build();
		Assert.equals("CURRENT_TIMESTAMP", definition.Columns[0].DefaultValue);
	}

	function testSchemaBuilder_Date_DefaultCurrentDate() {
		final definition = TableBuilder.Create().Table("Test").Date("BirthDate", c -> c.DefaultCurrentDate()).Build();
		Assert.equals(DatabaseColumnType.Date, definition.Columns[0].Type);
		Assert.equals("CURRENT_DATE", definition.Columns[0].DefaultValue);
	}

	function testSchemaBuilder_Time() {
		final definition = TableBuilder.Create().Table("Test").Time("OpenTime").Build();
		Assert.equals(DatabaseColumnType.Time, definition.Columns[0].Type);
	}

	function testSchemaBuilder_DateTimeOffset() {
		final definition = TableBuilder.Create().Table("Test").DateTimeOffset("EventTime").Build();
		Assert.equals(DatabaseColumnType.DateTimeOffset, definition.Columns[0].Type);
	}

	function testSchemaBuilder_Timestamp() {
		final definition = TableBuilder.Create().Table("Test").Timestamp("RowVersion").Build();
		Assert.equals(DatabaseColumnType.Timestamp, definition.Columns[0].Type);
	}

	// ---- Binary Columns ----

	function testSchemaBuilder_Binary_DefaultVarBinary() {
		final definition = TableBuilder.Create().Table("Test").Binary("Data").Build();
		final column = definition.Columns[0];
		Assert.equals(DatabaseColumnType.VarBinary, column.Type);
		Assert.equals(255, column.MaxLength);
	}

	function testSchemaBuilder_Binary_FixedLength() {
		final definition = TableBuilder.Create().Table("Test").Binary("Hash", c -> c.FixedLength(32)).Build();
		final column = definition.Columns[0];
		Assert.equals(DatabaseColumnType.Binary, column.Type);
		Assert.equals(32, column.MaxLength);
	}

	function testSchemaBuilder_Blob() {
		final definition = TableBuilder.Create().Table("Test").Blob("Image").Build();
		Assert.equals(DatabaseColumnType.Blob, definition.Columns[0].Type);
	}

	// ---- Special Types ----

	function testSchemaBuilder_Guid() {
		final definition = TableBuilder.Create().Table("Test").Guid("Id").Build();
		Assert.equals(DatabaseColumnType.Guid, definition.Columns[0].Type);
	}

	function testSchemaBuilder_Guid_DefaultNewGuid() {
		final definition = TableBuilder.Create().Table("Test").Guid("Id", c -> c.DefaultNewGuid()).Build();
		Assert.equals("NEWID()", definition.Columns[0].DefaultValue);
	}

	function testSchemaBuilder_Json() {
		final definition = TableBuilder.Create().Table("Test").Json("Metadata", c -> c.DefaultValue("{}")).Build();
		final column = definition.Columns[0];
		Assert.equals(DatabaseColumnType.Json, column.Type);
		Assert.equals("{}", column.DefaultValue);
	}

	function testSchemaBuilder_Xml() {
		final definition = TableBuilder.Create().Table("Test").Xml("XmlData").Build();
		Assert.equals(DatabaseColumnType.Xml, definition.Columns[0].Type);
	}

	// ---- Column Modifiers ----

	function testSchemaBuilder_Column_Nullable() {
		final definition = TableBuilder.Create().Table("Test").String("Name", c -> c.Nullable()).Build();
		Assert.isTrue(definition.Columns[0].IsNullable);
	}

	function testSchemaBuilder_Column_NotNull() {
		final definition = TableBuilder.Create().Table("Test").String("Name", c -> c.NotNull()).Build();
		Assert.isFalse(definition.Columns[0].IsNullable);
	}

	function testSchemaBuilder_Column_Comment() {
		final definition = TableBuilder.Create().Table("Test").String("Name", c -> c.Comment("User's full name")).Build();
		Assert.equals("User's full name", definition.Columns[0].Comment);
	}

	// ---- Primary Key ----

	function testSchemaBuilder_PrimaryKey_SingleColumn() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").PrimaryKey("PK_Users", ["Id"]).Build();
		final pk = Assert.single(definition.Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals("PK_Users", pk.Name);
		Assert.single(pk.Columns);
		Assert.equals("Id", pk.Columns[0]);
	}

	function testSchemaBuilder_PrimaryKey_CompositeKey() {
		final definition = TableBuilder.Create().Table("OrderItems").Int("OrderId").Int("ProductId")
			.PrimaryKey("PK_OrderItems", ["OrderId", "ProductId"]).Build();
		final pk = Assert.single(definition.Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals(2, pk.Columns.length);
	}

	function testSchemaBuilder_PrimaryKey_AutoNamed() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").PrimaryKey(["Id"]).Build();
		final pk = Assert.single(definition.Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals("PK_Users", pk.Name);
	}

	// ---- Foreign Key ----

	function testSchemaBuilder_ForeignKey_Basic() {
		final definition = TableBuilder.Create().Table("Orders").Int("Id").Int("UserId")
			.ForeignKey("FK_Orders_Users", fk -> fk.Column("UserId").References("Users", ["Id"])).Build();
		final fkConstraint = Assert.single(definition.Constraints.ofType(DatabaseForeignKeyConstraint));
		Assert.equals("FK_Orders_Users", fkConstraint.Name);
		Assert.equals("UserId", fkConstraint.Columns[0]);
		Assert.equals("Users", fkConstraint.ReferencedTable);
		Assert.equals("Id", fkConstraint.ReferencedColumns[0]);
	}

	function testSchemaBuilder_ForeignKey_WithActions() {
		final definition = TableBuilder.Create().Table("Orders").Int("Id").Int("UserId")
			.ForeignKey("FK_Orders_Users", fk -> fk.Column("UserId").References("Users", ["Id"])
				.OnDelete(DatabaseForeignKeyAction.Cascade).OnUpdate(DatabaseForeignKeyAction.Restrict)).Build();
		final fkConstraint = Assert.single(definition.Constraints.ofType(DatabaseForeignKeyConstraint));
		Assert.equals(DatabaseForeignKeyAction.Cascade, fkConstraint.OnDelete);
		Assert.equals(DatabaseForeignKeyAction.Restrict, fkConstraint.OnUpdate);
	}

	function testSchemaBuilder_ForeignKey_Cascade() {
		final definition = TableBuilder.Create().Table("Orders").Int("Id").Int("UserId")
			.ForeignKey("FK_Orders_Users", fk -> fk.Column("UserId").References("Users", ["Id"]).Cascade()).Build();
		final fkConstraint = Assert.single(definition.Constraints.ofType(DatabaseForeignKeyConstraint));
		Assert.equals(DatabaseForeignKeyAction.Cascade, fkConstraint.OnDelete);
		Assert.equals(DatabaseForeignKeyAction.Cascade, fkConstraint.OnUpdate);
	}

	function testSchemaBuilder_ForeignKey_CompositeKey() {
		final definition = TableBuilder.Create().Table("OrderItemDetails").Int("OrderId").Int("ProductId").Int("DetailId")
			.ForeignKey("FK_Details_OrderItems", fk -> fk.Columns(["OrderId", "ProductId"])
				.References("OrderItems", ["OrderId", "ProductId"])).Build();
		final fkConstraint = Assert.single(definition.Constraints.ofType(DatabaseForeignKeyConstraint));
		Assert.equals(2, fkConstraint.Columns.length);
		Assert.equals(2, fkConstraint.ReferencedColumns.length);
	}

	// ---- Unique Constraint ----

	function testSchemaBuilder_Unique_Named() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").String("Email").Unique("UQ_Users_Email", ["Email"]).Build();
		final uq = Assert.single(definition.Constraints.ofType(DatabaseUniqueConstraint));
		Assert.equals("UQ_Users_Email", uq.Name);
	}

	function testSchemaBuilder_Unique_AutoNamed() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").String("Email").Unique(["Email"]).Build();
		final uq = Assert.single(definition.Constraints.ofType(DatabaseUniqueConstraint));
		Assert.equals("UQ_Users_Email", uq.Name);
	}

	function testSchemaBuilder_Unique_MultiColumn() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").String("FirstName").String("LastName")
			.Unique(["FirstName", "LastName"]).Build();
		final uq = Assert.single(definition.Constraints.ofType(DatabaseUniqueConstraint));
		Assert.equals("UQ_Users_FirstName_LastName", uq.Name);
		Assert.equals(2, uq.Columns.length);
	}

	// ---- Check Constraint ----

	function testSchemaBuilder_Check() {
		final definition = TableBuilder.Create().Table("Products").Int("Id").Decimal("Price").Check("CK_Products_Price", "Price > 0").Build();
		final ck = Assert.single(definition.Constraints.ofType(DatabaseCheckConstraint));
		Assert.equals("CK_Products_Price", ck.Name);
		Assert.equals("Price > 0", ck.Expression);
	}

	// ---- Indexes ----

	function testSchemaBuilder_Index_Simple() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").String("Email").Index("IX_Users_Email", ["Email"]).Build();
		final idx = Assert.single(definition.Indexes);
		Assert.equals("IX_Users_Email", idx.Name);
		Assert.single(idx.Columns);
		Assert.equals("Email", idx.Columns[0].ColumnName);
		Assert.isFalse(idx.IsUnique);
	}

	function testSchemaBuilder_Index_MultiColumn() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").String("FirstName").String("LastName")
			.Index("IX_Users_Name", ["FirstName", "LastName"]).Build();
		final idx = Assert.single(definition.Indexes);
		Assert.equals(2, idx.Columns.length);
	}

	function testSchemaBuilder_Index_Unique() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").String("Email")
			.Index("IX_Users_Email", idx -> idx.Column("Email").Unique()).Build();
		Assert.isTrue(definition.Indexes[0].IsUnique);
	}

	function testSchemaBuilder_Index_Clustered() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").Index("IX_Users_Id", idx -> idx.Column("Id").Clustered()).Build();
		Assert.isTrue(definition.Indexes[0].IsClustered);
	}

	function testSchemaBuilder_Index_Descending() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").DateTime("CreatedAt")
			.Index("IX_Users_CreatedAt", idx -> idx.Descending("CreatedAt")).Build();
		final idx = definition.Indexes[0];
		Assert.equals(DatabaseSortOrder.Descending, idx.Columns[0].SortOrder);
	}

	function testSchemaBuilder_Index_MixedSortOrder() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").String("Name").DateTime("CreatedAt")
			.Index("IX_Users_Name_Created", idx -> idx.Ascending("Name").Descending("CreatedAt")).Build();
		final idx = definition.Indexes[0];
		Assert.equals(2, idx.Columns.length);
		Assert.equals(DatabaseSortOrder.Ascending, idx.Columns[0].SortOrder);
		Assert.equals(DatabaseSortOrder.Descending, idx.Columns[1].SortOrder);
	}

	function testSchemaBuilder_Index_WithFilter() {
		final definition = TableBuilder.Create().Table("Users").Int("Id").String("Email").Boolean("IsActive")
			.Index("IX_Users_Email_Active", idx -> idx.Column("Email").Filter("IsActive = 1")).Build();
		Assert.equals("IsActive = 1", definition.Indexes[0].FilterExpression);
	}

	// ---- EntityTableBuilder<T> typed column/constraint builder ----

	function testEntityTable_DefaultsTableNameToTypeName() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(Book).Column(b -> b.id);
		Assert.equals("Book", snapshot.Tables[0].TableName);
	}

	function testEntityTable_CustomTableName() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(Book, "Books").Column(b -> b.id);
		Assert.equals("Books", snapshot.Tables[0].TableName);
	}

	function testEntityTable_PropertyLambda_UsesPropertyName() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(Book)
			.Column(b -> b.id).AutoIncrement()
			.Column(b -> b.title).MaxLength(200).NotNull();
		final def = snapshot.Tables[0];
		Assert.equals(2, def.Columns.length);
		Assert.equals("id", def.Columns[0].Name);
		Assert.isTrue(def.Columns[0].IsAutoIncrement);
		Assert.equals("title", def.Columns[1].Name);
		Assert.equals(200, def.Columns[1].MaxLength);
	}

	function testEntityTable_NullableInt_DefaultsIsNullableTrue() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(TbTestEntity).Column(e -> e.nullableInt);
		Assert.isTrue(snapshot.Tables[0].Columns[0].IsNullable);
	}

	function testEntityTable_NonNullableInt_DefaultsIsNullableFalse() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(TbTestEntity).Column(e -> e.id);
		Assert.isFalse(snapshot.Tables[0].Columns[0].IsNullable);
	}

	function testEntityTable_ForeignKey() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(Book)
			.Column(b -> b.id)
			.Column(b -> b.authorId)
			.Column(b -> b.authorId).ForeignKey(Author, a -> a.id, null, null, "FK_Book_Author");
		final fk = Assert.single(snapshot.Tables[0].Constraints.ofType(DatabaseForeignKeyConstraint));
		Assert.equals("authorId", fk.Columns[0]);
		Assert.equals("Author", fk.ReferencedTable);
		Assert.equals("id", fk.ReferencedColumns[0]);
	}

	function testEntityTable_PrimaryKey() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(Book)
			.Column(b -> b.id)
			.Column(b -> b.id).PrimaryKey(null, false, "PK_Book");
		final pk = Assert.single(snapshot.Tables[0].Constraints.ofType(DatabasePrimaryKeyConstraint));
		Assert.equals("id", pk.Columns[0]);
	}

	function testEntityTable_Unique() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(Book)
			.Column(b -> b.id)
			.Column(b -> b.title).MaxLength(255)
			.Unique("UQ_Book_Title");
		final uq = Assert.single(snapshot.Tables[0].Constraints.ofType(DatabaseUniqueConstraint));
		Assert.equals("title", uq.Columns[0]);
	}

	function testEntityTable_DateTime() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(Book)
			.Column(b -> b.id)
			.Column(b -> b.publishedDate);
		final col = snapshot.Tables[0].Columns[1];
		Assert.equals("publishedDate", col.Name);
		// The shared Book declares its date as a `SqlDate`, which is a date rather than a moment.
		Assert.equals(DatabaseColumnType.Date, col.Type);
	}

	function testEntityTable_CheckExpression_RendersToSql() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(TbReview)
			.Column(r -> r.rating)
			.Check(r -> r >= 1 && r <= 5, "CK_Rating");
		final ck = Assert.single(snapshot.Tables[0].Constraints.ofType(DatabaseCheckConstraint));
		Assert.equals("CK_Rating", ck.Name);
		Assert.equals("rating >= 1 AND rating <= 5", ck.Expression);
	}

	function testEntityTable_CheckExpression_NullCompare_RendersIsNull() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(Author)
			.Column(a -> a.name).MaxLength(255)
			.Check(n -> n != null, "CK_Name_NotNull");
		final ck = Assert.single(snapshot.Tables[0].Constraints.ofType(DatabaseCheckConstraint));
		Assert.equals("name IS NOT NULL", ck.Expression);
	}

	function testEntityTable_BindsEntityTypeToTable() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(Book, "Books").Column(b -> b.id);
		Assert.isTrue(snapshot.Tables[0] == snapshot.GetTable(Book));
	}
}

private class TbReview {
	public var rating:Int = 0;

	public function new() {}
}

private class TbTestEntity {
	public var id:Int = 0;
	public var nullableInt:Null<Int>;

	public function new() {}
}
