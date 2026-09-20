package suites;

import codequery.Decimal;
import codequery.Guid;
import codequery.migrations.*;
import codequery.schemabuilder.DatabaseBuilder;
import codequery.schemabuilder.DatabaseTableBuilder;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.SqlType;
import codequery.sqlexpressions.TableConstraint;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/** `DatabaseBuilderTests.cs`. */
class DatabaseBuilderTests extends TestCase {
	// ---- Basic DatabaseBuilder Tests ----

	function testDatabaseBuilder_AddTable_UsesTypeNameByDefault() {
		final builder = new DatabaseBuilder();
		final tableBuilder = builder.AddTable(DbUser);
		final table = tableBuilder.Build();
		Assert.equals("DbUser", table.TableName);
	}

	function testDatabaseBuilder_AddTable_WithCustomName() {
		final builder = new DatabaseBuilder();
		final tableBuilder = builder.AddTable(DbUser, "Users");
		final table = tableBuilder.Build();
		Assert.equals("Users", table.TableName);
	}

	function testDatabaseBuilder_Tables_ReturnsRegisteredTables() {
		final builder = new DatabaseBuilder();
		builder.AddTable(DbUser, "Users").Build();
		builder.AddTable(DbOrder, "Orders").Build();
		Assert.equals(2, builder.Tables.length);
		Assert.isTrue(builder.Tables.any(t -> t.TableName == "Users"));
		Assert.isTrue(builder.Tables.any(t -> t.TableName == "Orders"));
	}

	// ---- SqlExpression Generation Tests ----

	function testDatabaseBuilder_ToCreateTableExpressions_GeneratesExpressions() {
		final builder = new DatabaseBuilder();
		final userTable = builder.AddTable(DbUser, "Users");
		userTable.Property(u -> u.id);
		userTable.Property(u -> u.name);
		userTable.Build();

		final expressions = builder.ToCreateTableExpressions();

		Assert.single(expressions);
		final createExpr = expressions[0];
		Assert.equals("Users", createExpr.TableName);
		Assert.equals(2, createExpr.Columns.length);
	}

	function testDatabaseBuilder_ToCreateTableExpressions_WithIfNotExists() {
		final builder = new DatabaseBuilder();
		final userTable = builder.AddTable(DbUser, "Users");
		userTable.Property(u -> u.id);
		userTable.Build();

		final expressions = builder.ToCreateTableExpressions(true);

		Assert.isTrue(expressions[0].IfNotExists);
	}

	function testDatabaseBuilder_ToSchemaExpressions_IncludesIndexes() {
		final builder = new DatabaseBuilder();
		final userTable = builder.AddTable(DbUser, "Users");
		userTable.Property(u -> u.id);
		userTable.Property(u -> u.email);
		userTable.HasIndex(u -> u.email);
		userTable.Build();

		final expressions = builder.ToSchemaExpressions();

		Assert.equals(2, expressions.length);
		Assert.isType(expressions[0], CreateTableExpression);
		Assert.isType(expressions[1], CreateIndexExpression);
	}

	function testCreateTableExpression_HasCorrectColumnDefinitions() {
		final builder = new DatabaseBuilder();
		final userTable = builder.AddTable(DbUser, "Users");
		userTable.Property(u -> u.id);
		userTable.Property(u -> u.name);
		userTable.Property(u -> u.isActive);
		userTable.Build();

		final createExpr = builder.ToCreateTableExpressions()[0];

		final idCol = createExpr.Columns.first(c -> c.Name == "id");
		Assert.equals(SqlInt, idCol.Type);
		Assert.isFalse(idCol.IsNullable);

		final nameCol = createExpr.Columns.first(c -> c.Name == "name");
		Assert.equals(SqlText, nameCol.Type);
		Assert.isTrue(nameCol.IsNullable);

		final isActiveCol = createExpr.Columns.first(c -> c.Name == "isActive");
		Assert.equals(SqlBool, isActiveCol.Type);
	}

	function testCreateTableExpression_HasPrimaryKeyConstraint() {
		final builder = new DatabaseBuilder();
		final userTable = builder.AddTable(DbUser, "Users");
		userTable.Property(u -> u.id);
		userTable.HasPrimaryKey(u -> u.id);
		userTable.Build();

		final createExpr = builder.ToCreateTableExpressions()[0];

		final pkConstraint = Assert.single(createExpr.Constraints.ofType(PrimaryKeyConstraint));
		Assert.equals("id", pkConstraint.Columns[0]);
	}

	function testCreateTableExpression_HasForeignKeyConstraint() {
		final builder = new DatabaseBuilder();
		final userTable = builder.AddTable(DbUser, "Users");
		userTable.Property(u -> u.id);
		userTable.Build();

		final orderTable = builder.AddTable(DbOrder, "Orders");
		orderTable.Property(o -> o.id);
		orderTable.Property(o -> o.userId);
		orderTable.HasForeignKey(DbUser, o -> o.userId, u -> u.id);
		orderTable.Build();

		final createExprs = builder.ToCreateTableExpressions();
		final orderExpr = createExprs.first(e -> e.TableName == "Orders");

		final fkConstraint = Assert.single(orderExpr.Constraints.ofType(ForeignKeyConstraint));
		Assert.equals("userId", fkConstraint.Columns[0]);
		Assert.equals("Users", fkConstraint.ReferencedTable);
		Assert.equals("id", fkConstraint.ReferencedColumns[0]);
	}

	function testCreateTableExpression_HasUniqueConstraint() {
		final builder = new DatabaseBuilder();
		final userTable = builder.AddTable(DbUser, "Users");
		userTable.Property(u -> u.id);
		userTable.Property(u -> u.email);
		userTable.HasUnique(u -> u.email);
		userTable.Build();

		final createExpr = builder.ToCreateTableExpressions()[0];

		final uqConstraint = Assert.single(createExpr.Constraints.ofType(UniqueConstraint));
		Assert.equals("email", uqConstraint.Columns[0]);
	}

	function testCreateIndexExpression_HasCorrectProperties() {
		final builder = new DatabaseBuilder();
		final userTable = builder.AddTable(DbUser, "Users");
		userTable.Property(u -> u.id);
		userTable.Property(u -> u.email);
		userTable.HasIndex("IX_Users_Email", idx -> idx.Column("email").Unique().Filter("email IS NOT NULL"));
		userTable.Build();

		final expressions = builder.ToSchemaExpressions();
		final indexExpr = expressions.ofType(CreateIndexExpression).single();

		Assert.equals("IX_Users_Email", indexExpr.IndexName);
		Assert.equals("Users", indexExpr.TableName);
		Assert.isTrue(indexExpr.IsUnique);
		Assert.equals("email IS NOT NULL", indexExpr.FilterExpression);
	}

	// ---- Complete Schema Configuration Tests ----

	function testDatabaseBuilder_CompleteUserOrderSchema() {
		final builder = new DatabaseBuilder();

		final userTable = builder.AddTable(DbUser, "Users");
		userTable.Property(u -> u.id);
		userTable.Property(u -> u.name);
		userTable.Property(u -> u.email);
		userTable.Property(u -> u.createdAt);
		userTable.Property(u -> u.isActive);
		userTable.HasPrimaryKey(u -> u.id);
		userTable.HasUnique(u -> u.email);
		userTable.HasIndex(u -> u.name);
		userTable.Build();

		final orderTable = builder.AddTable(DbOrder, "Orders");
		orderTable.Property(o -> o.id);
		orderTable.Property(o -> o.userId);
		orderTable.Property(o -> o.total);
		orderTable.Property(o -> o.orderDate);
		orderTable.HasPrimaryKey(o -> o.id);
		orderTable.HasForeignKey(DbUser, o -> o.userId, u -> u.id, DatabaseForeignKeyAction.Cascade, DatabaseForeignKeyAction.NoAction);
		orderTable.HasIndex(o -> o.userId);
		orderTable.Build();

		final expressions = builder.ToSchemaExpressions();

		// 2 CREATE TABLE + 2 CREATE INDEX
		Assert.equals(4, expressions.length);
		Assert.equals(2, expressions.ofType(CreateTableExpression).length);
		Assert.equals(2, expressions.ofType(CreateIndexExpression).length);

		final usersExpr = expressions.ofType(CreateTableExpression).first(e -> e.TableName == "Users");
		Assert.equals(5, usersExpr.Columns.length);
		Assert.single(usersExpr.Constraints.ofType(PrimaryKeyConstraint));
		Assert.single(usersExpr.Constraints.ofType(UniqueConstraint));

		final ordersExpr = expressions.ofType(CreateTableExpression).first(e -> e.TableName == "Orders");
		Assert.equals(4, ordersExpr.Columns.length);
		final fk = Assert.single(ordersExpr.Constraints.ofType(ForeignKeyConstraint));
		Assert.equals(ForeignKeyAction.Cascade, fk.OnDelete);
	}

	function testDatabaseBuilder_ProductCategorySchema_WithGuidAndNullable() {
		final builder = new DatabaseBuilder();

		final categoryTable = builder.AddTable(DbCategory, "Categories");
		categoryTable.Property(c -> c.id);
		categoryTable.Property(c -> c.name);
		categoryTable.HasPrimaryKey(c -> c.id);
		categoryTable.Build();

		final productTable = builder.AddTable(DbProduct, "Products");
		productTable.Property(p -> p.id);
		productTable.Property(p -> p.name);
		productTable.Property(p -> p.price);
		productTable.Property(p -> p.categoryId);
		productTable.HasPrimaryKey(p -> p.id);
		productTable.HasForeignKey(DbCategory, p -> p.categoryId, c -> c.id, DatabaseForeignKeyAction.SetNull);
		productTable.HasCheck("CK_Products_Price", p -> p.price >= 0);
		productTable.Build();

		final expressions = builder.ToSchemaExpressions();

		final productExpr = expressions.ofType(CreateTableExpression).first(e -> e.TableName == "Products");

		final idCol = productExpr.Columns.first(c -> c.Name == "id");
		Assert.equals(SqlGuid, idCol.Type);

		final categoryIdCol = productExpr.Columns.first(c -> c.Name == "categoryId");
		Assert.isTrue(categoryIdCol.IsNullable);

		final fk = Assert.single(productExpr.Constraints.ofType(ForeignKeyConstraint));
		Assert.equals(ForeignKeyAction.SetNull, fk.OnDelete);

		Assert.single(productExpr.Constraints.ofType(CheckConstraint));
	}
}

private class DbUser {
	public var id:Int = 0;
	public var name:String = "";
	public var email:String = "";
	public var createdAt:Date;
	public var isActive:Bool = false;

	public function new() {}
}

private class DbOrder {
	public var id:Int = 0;
	public var userId:Int = 0;
	public var total:Decimal = 0;
	public var orderDate:Date;

	public function new() {}
}

private class DbProduct {
	public var id:Guid;
	public var name:String = "";
	public var price:Decimal = 0;
	public var categoryId:Null<Int>;

	public function new() {}
}

private class DbCategory {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}
