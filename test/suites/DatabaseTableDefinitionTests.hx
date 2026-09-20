package suites;

import codequery.migrations.*;
import codequery.schemabuilder.TableBuilder;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.SqlType;
import codequery.sqlexpressions.TableConstraint;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/** `DatabaseTableDefinitionTests.cs`. */
class DatabaseTableDefinitionTests extends TestCase {
	// ---- Diff - New Table (from null) ----

	function testDiff_FromNull_CreatesTable() {
		final to = TableBuilder.Create().Table("Users")
			.Int("Id", c -> c.Identity())
			.String("Name", c -> c.MaxLength(100))
			.PrimaryKey("PK_Users", ["Id"])
			.Build();

		final changes = to.Diff(null);

		Assert.single(changes.filter(c -> c.ChangeType == SchemaChangeType.CreateTable));
		final createTable = Assert.isType(changes[0], CreateTableExpression);
		Assert.equals("Users", createTable.TableName);
		Assert.equals(2, createTable.Columns.length);
		Assert.single(createTable.Constraints);
	}

	function testDiff_FromNull_CreatesTableWithIndexes() {
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Email").Index("IX_Users_Email", ["Email"]).Build();

		final changes = to.Diff(null);

		Assert.equals(2, changes.length);
		Assert.isType(changes[0], CreateTableExpression);
		final createIndex = Assert.isType(changes[1], CreateIndexExpression);
		Assert.equals("IX_Users_Email", createIndex.IndexName);
	}

	// ---- Diff - Table Rename ----

	function testDiff_TableRename_ProducesRenameExpression() {
		final from = TableBuilder.Create().Table("OldUsers").Int("Id").Build();
		final to = TableBuilder.Create().Table("NewUsers").Int("Id").Build();

		final changes = to.Diff(from);

		final rename = Assert.single(changes.ofType(RenameTableExpression));
		Assert.equals("OldUsers", rename.OldTableName);
		Assert.equals("NewUsers", rename.NewTableName);
	}

	// ---- Diff - Column Changes ----

	function testDiff_AddColumn_ProducesAddColumnExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Email", c -> c.MaxLength(200)).Build();

		final changes = to.Diff(from);

		final addColumn = Assert.single(changes.ofType(AddColumnExpression));
		Assert.equals("Users", addColumn.TableName);
		Assert.equals("Email", addColumn.Column.Name);
		Assert.equals(SqlText, addColumn.Column.Type);
		Assert.equals(200, addColumn.Column.MaxLength);
	}

	function testDiff_DropColumn_ProducesDropColumnExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("Email").String("Phone").Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Email").Build();

		final changes = to.Diff(from);

		final dropColumn = Assert.single(changes.ofType(DropColumnExpression));
		Assert.equals("Users", dropColumn.TableName);
		Assert.equals("Phone", dropColumn.ColumnName);
	}

	function testDiff_AlterColumnType_ProducesAlterColumnExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("Age", c -> c.MaxLength(10)).Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").Int("Age").Build();

		final changes = to.Diff(from);

		final alterColumn = Assert.single(changes.ofType(AlterColumnExpression));
		Assert.equals("Age", alterColumn.ColumnName);
		Assert.equals(SqlInt, alterColumn.NewDefinition.Type);
	}

	function testDiff_AlterColumnNullability_ProducesAlterColumnExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("Email", c -> c.NotNull()).Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Email", c -> c.Nullable()).Build();

		final changes = to.Diff(from);

		final alterColumn = Assert.single(changes.ofType(AlterColumnExpression));
		Assert.equals("Email", alterColumn.ColumnName);
		Assert.isTrue(alterColumn.NewDefinition.IsNullable);
		Assert.isFalse(alterColumn.OldDefinition.IsNullable);
	}

	function testDiff_AlterColumnMaxLength_ProducesAlterColumnExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("Name", c -> c.MaxLength(50)).Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Name", c -> c.MaxLength(200)).Build();

		final changes = to.Diff(from);

		final alterColumn = Assert.single(changes.ofType(AlterColumnExpression));
		Assert.equals("Name", alterColumn.ColumnName);
		Assert.equals(200, alterColumn.NewDefinition.MaxLength);
		Assert.equals(50, alterColumn.OldDefinition.MaxLength);
	}

	function testDiff_AlterColumnDefault_ProducesAlterColumnExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").Boolean("IsActive", c -> c.DefaultValue(false)).Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").Boolean("IsActive", c -> c.DefaultValue(true)).Build();

		final changes = to.Diff(from);

		final alterColumn = Assert.single(changes.ofType(AlterColumnExpression));
		Assert.equals("IsActive", alterColumn.ColumnName);
	}

	function testDiff_MultipleColumnChanges_ProducesMultipleExpressions() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("Name").String("OldField").Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Name", c -> c.MaxLength(500)).String("NewField").Build();

		final changes = to.Diff(from);

		Assert.single(changes.ofType(DropColumnExpression));
		Assert.single(changes.ofType(AddColumnExpression));
		Assert.single(changes.ofType(AlterColumnExpression));
	}

	// ---- Diff - Constraint Changes ----

	function testDiff_AddPrimaryKey_ProducesAddConstraintExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").PrimaryKey("PK_Users", ["Id"]).Build();

		final changes = to.Diff(from);

		final addConstraint = Assert.single(changes.ofType(AddConstraintExpression));
		Assert.isType(addConstraint.Constraint, PrimaryKeyConstraint);
		Assert.equals("PK_Users", addConstraint.Constraint.Name);
	}

	function testDiff_DropPrimaryKey_ProducesDropConstraintExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").PrimaryKey("PK_Users", ["Id"]).Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").Build();

		final changes = to.Diff(from);

		final dropConstraint = Assert.single(changes.ofType(DropConstraintExpression));
		Assert.equals("PK_Users", dropConstraint.ConstraintName);
	}

	function testDiff_AddForeignKey_ProducesAddConstraintExpression() {
		final from = TableBuilder.Create().Table("Orders").Int("Id").Int("UserId").Build();
		final to = TableBuilder.Create().Table("Orders").Int("Id").Int("UserId")
			.ForeignKey("FK_Orders_Users", fk -> fk.Column("UserId").References("Users", ["Id"]).OnDelete(DatabaseForeignKeyAction.Cascade))
			.Build();

		final changes = to.Diff(from);

		final addConstraint = Assert.single(changes.ofType(AddConstraintExpression));
		final fkConstraint = Assert.isType(addConstraint.Constraint, ForeignKeyConstraint);
		Assert.equals("FK_Orders_Users", fkConstraint.Name);
		Assert.equals("Users", fkConstraint.ReferencedTable);
		Assert.equals(ForeignKeyAction.Cascade, fkConstraint.OnDelete);
	}

	function testDiff_ModifyForeignKeyAction_ProducesDropAndAdd() {
		final from = TableBuilder.Create().Table("Orders").Int("Id").Int("UserId")
			.ForeignKey("FK_Orders_Users", fk -> fk.Column("UserId").References("Users", ["Id"]).OnDelete(DatabaseForeignKeyAction.NoAction))
			.Build();
		final to = TableBuilder.Create().Table("Orders").Int("Id").Int("UserId")
			.ForeignKey("FK_Orders_Users", fk -> fk.Column("UserId").References("Users", ["Id"]).OnDelete(DatabaseForeignKeyAction.Cascade))
			.Build();

		final changes = to.Diff(from);

		Assert.single(changes.ofType(DropConstraintExpression));
		Assert.single(changes.ofType(AddConstraintExpression));
	}

	function testDiff_AddUniqueConstraint_ProducesAddConstraintExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("Email").Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Email").Unique("UQ_Users_Email", ["Email"]).Build();

		final changes = to.Diff(from);

		final addConstraint = Assert.single(changes.ofType(AddConstraintExpression));
		final uqConstraint = Assert.isType(addConstraint.Constraint, UniqueConstraint);
		Assert.equals("UQ_Users_Email", uqConstraint.Name);
	}

	function testDiff_AddCheckConstraint_ProducesAddConstraintExpression() {
		final from = TableBuilder.Create().Table("Products").Int("Id").Decimal("Price").Build();
		final to = TableBuilder.Create().Table("Products").Int("Id").Decimal("Price").Check("CK_Products_Price", "Price > 0").Build();

		final changes = to.Diff(from);

		final addConstraint = Assert.single(changes.ofType(AddConstraintExpression));
		Assert.isType(addConstraint.Constraint, CheckConstraint);
	}

	// ---- Diff - Index Changes ----

	function testDiff_AddIndex_ProducesCreateIndexExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("Email").Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Email").Index("IX_Users_Email", ["Email"]).Build();

		final changes = to.Diff(from);

		final createIndex = Assert.single(changes.ofType(CreateIndexExpression));
		Assert.equals("IX_Users_Email", createIndex.IndexName);
		Assert.equals("Users", createIndex.TableName);
		Assert.single(createIndex.Columns);
		Assert.equals("Email", createIndex.Columns[0].ColumnName);
	}

	function testDiff_DropIndex_ProducesDropIndexExpression() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("Email").Index("IX_Users_Email", ["Email"]).Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Email").Build();

		final changes = to.Diff(from);

		final dropIndex = Assert.single(changes.ofType(DropIndexExpression));
		Assert.equals("IX_Users_Email", dropIndex.IndexName);
	}

	function testDiff_ModifyIndexColumns_ProducesDropAndCreate() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("FirstName").String("LastName")
			.Index("IX_Users_Name", idx -> idx.Column("FirstName")).Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("FirstName").String("LastName")
			.Index("IX_Users_Name", idx -> idx.Columns(["FirstName", "LastName"])).Build();

		final changes = to.Diff(from);

		Assert.single(changes.ofType(DropIndexExpression));
		Assert.single(changes.ofType(CreateIndexExpression));
	}

	function testDiff_AddUniqueIndex_ProducesCreateIndexWithUniqueFlag() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("Email").Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Email")
			.Index("IX_Users_Email", idx -> idx.Column("Email").Unique()).Build();

		final changes = to.Diff(from);

		final createIndex = Assert.single(changes.ofType(CreateIndexExpression));
		Assert.isTrue(createIndex.IsUnique);
	}

	function testDiff_ModifyIndexUniqueness_ProducesDropAndCreate() {
		final from = TableBuilder.Create().Table("Users").Int("Id").String("Email")
			.Index("IX_Users_Email", idx -> idx.Column("Email")).Build();
		final to = TableBuilder.Create().Table("Users").Int("Id").String("Email")
			.Index("IX_Users_Email", idx -> idx.Column("Email").Unique()).Build();

		final changes = to.Diff(from);

		final dropIndex = Assert.single(changes.ofType(DropIndexExpression));
		final createIndex = Assert.single(changes.ofType(CreateIndexExpression));
		Assert.isFalse(from.Indexes[0].IsUnique);
		Assert.isTrue(createIndex.IsUnique);
	}

	// ---- Diff - No Changes ----

	function testDiff_IdenticalSchemas_ProducesNoChanges() {
		final build = () -> TableBuilder.Create().Table("Users")
			.Int("Id", c -> c.Identity())
			.String("Name", c -> c.MaxLength(100).NotNull())
			.String("Email", c -> c.MaxLength(200).Nullable())
			.DateTime("CreatedAt", c -> c.DefaultCurrentTimestamp())
			.PrimaryKey("PK_Users", ["Id"])
			.Unique("UQ_Users_Email", ["Email"])
			.Index("IX_Users_Name", ["Name"])
			.Build();
		final from = build();
		final to = build();

		final changes = to.Diff(from);

		Assert.empty(changes);
	}

	// ---- Diff - Complex Scenarios ----

	function testDiff_ComplexMigration_ProducesCorrectChanges() {
		final from = TableBuilder.Create().Table("Users")
			.Int("Id", c -> c.Identity())
			.String("Username", c -> c.MaxLength(50))
			.String("Password", c -> c.MaxLength(100))
			.String("Email", c -> c.MaxLength(100))
			.PrimaryKey("PK_Users", ["Id"])
			.Index("IX_Users_Username", ["Username"])
			.Build();

		final to = TableBuilder.Create().Table("Users")
			.Int("Id", c -> c.Identity())
			.String("Username", c -> c.MaxLength(100)) // Changed max length
			.String("Email", c -> c.MaxLength(200)) // Changed max length
			.String("PasswordHash", c -> c.MaxLength(256)) // Renamed/replaced
			.DateTime("LastLogin", c -> c.Nullable()) // New column
			.PrimaryKey("PK_Users", ["Id"])
			.Unique("UQ_Users_Email", ["Email"]) // New constraint
			.Index("IX_Users_Username", idx -> idx.Column("Username").Unique()) // Modified index
			.Build();

		final changes = to.Diff(from);

		// Dropped Password, Added PasswordHash and LastLogin
		Assert.single(changes.ofType(DropColumnExpression).filter(c -> c.ColumnName == "Password"));
		Assert.single(changes.ofType(AddColumnExpression).filter(c -> c.Column.Name == "PasswordHash"));
		Assert.single(changes.ofType(AddColumnExpression).filter(c -> c.Column.Name == "LastLogin"));

		// Altered Username and Email
		Assert.equals(2, changes.ofType(AlterColumnExpression).length);

		// New unique constraint
		Assert.single(changes.ofType(AddConstraintExpression));

		// Modified index (drop + create)
		Assert.single(changes.ofType(DropIndexExpression));
		Assert.single(changes.ofType(CreateIndexExpression));
	}

	// ---- Static Diff Method ----

	function testStaticDiff_FromNull_BehavesLikeInstanceMethod() {
		final to = TableBuilder.Create().Table("Users").Int("Id").Build();

		final instanceChanges = to.Diff(null);
		final staticChanges = DatabaseTableDefinition.DiffFrom(null, to);

		Assert.equals(instanceChanges.length, staticChanges.length);
		Assert.equals(instanceChanges[0].ChangeType, staticChanges[0].ChangeType);
	}
}
