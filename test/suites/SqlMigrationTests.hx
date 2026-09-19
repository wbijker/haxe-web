package suites;

import codequery.migrations.SqlMigration;
import codequery.migrations.TableBuilder;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.TableConstraint;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `SqlMigrationTests.cs`. The one dialect here stands in for both SQLite and PostgreSQL, bare identifiers throughout. */
class SqlMigrationTests extends TestCase {
	final driver = new SqlTranslator();

	static function ofType<T:{}>(ops:Array<SchemaChangeExpression>, cls:Class<T>):Array<T> {
		return [for (op in ops) if (Std.isOfType(op, cls)) (cast op : T)];
	}

	// ---- creation ----

	function testMigration_FromOperations_ContainsAllOperations() {
		final operations:Array<SchemaChangeExpression> = [
			new DropTableExpression("OldTable"),
			new CreateTableExpression("NewTable", [new ColumnDefinition("Id", SqlInt, false)])
		];
		final migration = SqlMigration.FromOperations("TestMigration", operations);
		Assert.equals("TestMigration", migration.Name);
		Assert.equals(2, migration.Operations.length);
		Assert.isType(migration.Operations[0], DropTableExpression);
		Assert.isType(migration.Operations[1], CreateTableExpression);
	}

	function testMigration_FromDiff_GeneratesChanges() {
		final from = TableBuilder.Create().Table("Users").Int("Id").Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Email").Build();
		final migration = SqlMigration.FromDiff("AddEmailColumn", from, to);
		Assert.equals("AddEmailColumn", migration.Name);
		final addColumn = Assert.single(ofType(migration.Operations, AddColumnExpression));
		Assert.equals("Email", addColumn.Column.Name);
	}

	// ---- fluent API ----

	function testMigration_FluentApi_CreateTable() {
		final columns = [new ColumnDefinition("Id", SqlInt, false), new ColumnDefinition("Name", SqlText, false, null, 100)];
		final constraints:Array<TableConstraint> = [new PrimaryKeyConstraint(["Id"], "PK_Users")];
		final migration = new SqlMigration("CreateUsersTable").CreateTable("Users", columns, constraints);
		final createTable = Assert.single(ofType(migration.Operations, CreateTableExpression));
		Assert.equals("Users", createTable.TableName);
		Assert.equals(2, createTable.Columns.length);
		Assert.single(createTable.Constraints);
	}

	function testMigration_FluentApi_DropTable() {
		final migration = new SqlMigration("DropOldTable").DropTable("OldTable", null, true);
		final drop = Assert.single(ofType(migration.Operations, DropTableExpression));
		Assert.equals("OldTable", drop.TableName);
		Assert.isTrue(drop.IfExists);
	}

	function testMigration_FluentApi_RenameTable() {
		final migration = new SqlMigration("RenameUsersTable").RenameTable("OldUsers", "NewUsers");
		final rename = Assert.single(ofType(migration.Operations, RenameTableExpression));
		Assert.equals("OldUsers", rename.OldTableName);
		Assert.equals("NewUsers", rename.NewTableName);
	}

	function testMigration_FluentApi_AddColumn() {
		final migration = new SqlMigration("AddEmailColumn").AddColumn("Users", new ColumnDefinition("Email", SqlText, true, null, 200));
		final addCol = Assert.single(ofType(migration.Operations, AddColumnExpression));
		Assert.equals("Users", addCol.TableName);
		Assert.equals("Email", addCol.Column.Name);
	}

	function testMigration_FluentApi_DropColumn() {
		final migration = new SqlMigration("DropOldColumn").DropColumn("Users", "OldColumn");
		final dropCol = Assert.single(ofType(migration.Operations, DropColumnExpression));
		Assert.equals("Users", dropCol.TableName);
		Assert.equals("OldColumn", dropCol.ColumnName);
	}

	function testMigration_FluentApi_RenameColumn() {
		final migration = new SqlMigration("RenameColumn").RenameColumn("Users", "OldName", "NewName");
		final rename = Assert.single(ofType(migration.Operations, RenameColumnExpression));
		Assert.equals("Users", rename.TableName);
		Assert.equals("OldName", rename.OldColumnName);
		Assert.equals("NewName", rename.NewColumnName);
	}

	function testMigration_FluentApi_AddConstraint() {
		final migration = new SqlMigration("AddUniqueConstraint").AddConstraint("Users", new UniqueConstraint(["Email"], "UQ_Users_Email"));
		final addConst = Assert.single(ofType(migration.Operations, AddConstraintExpression));
		Assert.equals("Users", addConst.TableName);
		Assert.isType(addConst.Constraint, UniqueConstraint);
	}

	function testMigration_FluentApi_DropConstraint() {
		final migration = new SqlMigration("DropConstraint").DropConstraint("Users", "UQ_Users_Email");
		final dropConst = Assert.single(ofType(migration.Operations, DropConstraintExpression));
		Assert.equals("Users", dropConst.TableName);
		Assert.equals("UQ_Users_Email", dropConst.ConstraintName);
	}

	function testMigration_FluentApi_CreateIndex() {
		final migration = new SqlMigration("CreateEmailIndex").CreateIndex("Users", "IX_Users_Email", [new IndexColumnDefinition("Email")], true);
		final createIdx = Assert.single(ofType(migration.Operations, CreateIndexExpression));
		Assert.equals("Users", createIdx.TableName);
		Assert.equals("IX_Users_Email", createIdx.IndexName);
		Assert.isTrue(createIdx.IsUnique);
	}

	function testMigration_FluentApi_DropIndex() {
		final migration = new SqlMigration("DropIndex").DropIndex("Users", "IX_Users_Email", null, true);
		final dropIdx = Assert.single(ofType(migration.Operations, DropIndexExpression));
		Assert.equals("Users", dropIdx.TableName);
		Assert.equals("IX_Users_Email", dropIdx.IndexName);
		Assert.isTrue(dropIdx.IfExists);
	}

	function testMigration_FluentApi_ChainedOperations() {
		final migration = new SqlMigration("ComplexMigration")
			.DropColumn("Users", "OldColumn")
			.AddColumn("Users", new ColumnDefinition("NewColumn", SqlText, true))
			.CreateIndex("Users", "IX_Users_NewColumn", [new IndexColumnDefinition("NewColumn")]);
		Assert.equals(3, migration.Operations.length);
		Assert.isType(migration.Operations[0], DropColumnExpression);
		Assert.isType(migration.Operations[1], AddColumnExpression);
		Assert.isType(migration.Operations[2], CreateIndexExpression);
	}

	// ---- rendering ----

	function testToSql_CreateTable_Sqlite() {
		final columns = [new ColumnDefinition("Id", SqlInt, false), new ColumnDefinition("Name", SqlText, false, null, 100)];
		final statements = new SqlMigration("Test").CreateTable("Users", columns).ToSql(driver);
		Assert.single(statements);
		Assert.contains("CREATE TABLE", statements[0]);
		Assert.contains("Users", statements[0]);
		Assert.contains("Id", statements[0]);
		Assert.contains("Name", statements[0]);
	}

	function testToSql_DropTable_Sqlite() {
		final statements = new SqlMigration("Test").DropTable("OldTable", null, true).ToSql(driver);
		Assert.single(statements);
		Assert.equals("DROP TABLE IF EXISTS OldTable", statements[0]);
	}

	function testToSql_RenameTable_Sqlite() {
		final statements = new SqlMigration("Test").RenameTable("OldName", "NewName").ToSql(driver);
		Assert.single(statements);
		Assert.equals("ALTER TABLE OldName RENAME TO NewName", statements[0]);
	}

	function testToSql_AddColumn_Sqlite() {
		final statements = new SqlMigration("Test").AddColumn("Users", new ColumnDefinition("Email", SqlText, true, null, 200)).ToSql(driver);
		Assert.single(statements);
		Assert.contains("ALTER TABLE Users ADD COLUMN", statements[0]);
		Assert.contains("Email", statements[0]);
	}

	function testToSql_DropColumn_Sqlite() {
		final statements = new SqlMigration("Test").DropColumn("Users", "OldColumn").ToSql(driver);
		Assert.single(statements);
		Assert.equals("ALTER TABLE Users DROP COLUMN OldColumn", statements[0]);
	}

	function testToSql_RenameColumn_Sqlite() {
		final statements = new SqlMigration("Test").RenameColumn("Users", "OldName", "NewName").ToSql(driver);
		Assert.single(statements);
		Assert.equals("ALTER TABLE Users RENAME COLUMN OldName TO NewName", statements[0]);
	}

	function testToSql_CreateIndex_Sqlite() {
		final columns = [new IndexColumnDefinition("LastName"), new IndexColumnDefinition("FirstName", true)];
		final statements = new SqlMigration("Test").CreateIndex("Users", "IX_Users_Name", columns).ToSql(driver);
		Assert.single(statements);
		Assert.contains("CREATE INDEX", statements[0]);
		Assert.contains("IX_Users_Name", statements[0]);
		Assert.contains("LastName", statements[0]);
		Assert.contains("FirstName DESC", statements[0]);
	}

	function testToSql_CreateUniqueIndex_Sqlite() {
		final statements = new SqlMigration("Test").CreateIndex("Users", "IX_Users_Email", [new IndexColumnDefinition("Email")], true).ToSql(driver);
		Assert.single(statements);
		Assert.contains("CREATE UNIQUE INDEX", statements[0]);
	}

	function testToSql_DropIndex_Sqlite() {
		final statements = new SqlMigration("Test").DropIndex("Users", "IX_Users_Email").ToSql(driver);
		Assert.single(statements);
		Assert.equals("DROP INDEX IX_Users_Email", statements[0]);
	}

	function testToSqlScript_GeneratesCompleteScript() {
		final script = new SqlMigration("Test")
			.DropColumn("Users", "OldColumn")
			.AddColumn("Users", new ColumnDefinition("NewColumn", SqlText, true))
			.ToSqlScript(driver);
		Assert.contains("DROP COLUMN", script);
		Assert.contains("ADD COLUMN", script);
		Assert.endsWith(";", script);
	}

	function testToSql_CreateTable_Postgres() {
		final columns = [new ColumnDefinition("Id", SqlInt, false), new ColumnDefinition("Name", SqlText, false, null, 100)];
		final statements = new SqlMigration("Test").CreateTable("Users", columns, null, "public").ToSql(driver);
		Assert.single(statements);
		Assert.contains("CREATE TABLE", statements[0]);
		Assert.contains("public.Users", statements[0]);
	}

	function testToSql_DropTableCascade_Postgres() {
		final statements = new SqlMigration("Test").DropTable("OldTable", null, false, true).ToSql(driver);
		Assert.single(statements);
		Assert.contains("DROP TABLE", statements[0]);
		Assert.contains("CASCADE", statements[0]);
	}

	function testToSql_AddConstraint_Postgres() {
		final constraint = new ForeignKeyConstraint(["UserId"], "Users", ["Id"], Cascade, NoAction, "FK_Orders_Users");
		final statements = new SqlMigration("Test").AddConstraint("Orders", constraint).ToSql(driver);
		Assert.single(statements);
		Assert.contains("ALTER TABLE Orders ADD", statements[0]);
		Assert.contains("CONSTRAINT FK_Orders_Users", statements[0]);
		Assert.contains("FOREIGN KEY", statements[0]);
		Assert.contains("REFERENCES Users", statements[0]);
		Assert.contains("ON DELETE CASCADE", statements[0]);
	}

	function testToSql_DropConstraint_Postgres() {
		final statements = new SqlMigration("Test").DropConstraint("Orders", "FK_Orders_Users").ToSql(driver);
		Assert.single(statements);
		Assert.equals("ALTER TABLE Orders DROP CONSTRAINT FK_Orders_Users", statements[0]);
	}

	// ---- with a table definition ----

	function testMigration_CreateTableFromDefinition() {
		final definition = TableBuilder.Create()
			.Table("Products")
			.Int("Id", c -> c.Identity())
			.String("Name", c -> c.MaxLength(200).NotNull())
			.Decimal("Price", c -> c.Precision(18, 2))
			.PrimaryKey("PK_Products", ["Id"])
			.Index("IX_Products_Name", ["Name"])
			.Build();
		final migration = new SqlMigration("CreateProductsTable").CreateTableFrom(definition);
		Assert.single(migration.Operations);
		final createTable = Assert.isType(migration.Operations[0], CreateTableExpression);
		Assert.equals("Products", createTable.TableName);
		Assert.equals(3, createTable.Columns.length);
	}

	function testMigration_FromDiff_ComplexChanges() {
		final from = TableBuilder.Create()
			.Table("Users").Int("Id").String("Name").String("OldEmail").Index("IX_Users_OldEmail", ["OldEmail"]).Build();
		final to = TableBuilder.Create()
			.Table("Users").Int("Id").String("Name", c -> c.MaxLength(200)).String("Email").Index("IX_Users_Email", ["Email"]).Build();
		final migration = SqlMigration.FromDiff("UpdateUsersSchema", from, to);

		// Alter Name, drop OldEmail, add Email, drop old index, create new index.
		Assert.isTrue(migration.Operations.length >= 4);
		Assert.isTrue(Lambda.exists(ofType(migration.Operations, DropColumnExpression), dc -> dc.ColumnName == "OldEmail"));
		Assert.isTrue(Lambda.exists(ofType(migration.Operations, AddColumnExpression), ac -> ac.Column.Name == "Email"));
		Assert.isTrue(Lambda.exists(ofType(migration.Operations, DropIndexExpression), di -> di.IndexName == "IX_Users_OldEmail"));
		Assert.isTrue(Lambda.exists(ofType(migration.Operations, CreateIndexExpression), ci -> ci.IndexName == "IX_Users_Email"));
	}
}
