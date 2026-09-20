package suites;

import codequery.DatabaseContext;
import codequery.Decimal;
import codequery.migrations.*;
import codequery.schemabuilder.TableBuilder;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;
using codequery.testing.TestSchemaHelpers;

/** `DatabaseContextTests.cs`. */
class DatabaseContextTests extends TestCase {
	final driver = new SqlTranslator();

	// ---- Registration ----

	function testRegister_WithDefinition_AddsTable() {
		final ctx = new DatabaseContext(driver);
		final definition = TableBuilder.Create().Table("Users").Int("Id").Build();

		ctx.Register(CtxUser, definition);

		Assert.single(ctx.Tables);
		Assert.equals("Users", ctx.GetTableName(CtxUser));
	}

	function testRegister_WithEntityTableBuilder_AddsTable() {
		final ctx = new DatabaseContext(driver);
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(CtxUser, "Users")
			.Column(u -> u.id).AutoIncrement()
			.Column(u -> u.name).MaxLength(100).NotNull();

		ctx.Register(CtxUser, snapshot.GetTable(CtxUser));

		Assert.single(ctx.Tables);
		final definition = ctx.GetTableDefinition(CtxUser);
		Assert.equals("Users", definition.TableName);
		Assert.equals(2, definition.Columns.length);
	}

	function testRegister_WithName_AddsTableWithName() {
		final ctx = new DatabaseContext(driver);
		ctx.Register(CtxUser, "CustomUsers");
		Assert.equals("CustomUsers", ctx.GetTableName(CtxUser));
	}

	function testRegister_WithoutName_UsesTypeName() {
		final ctx = new DatabaseContext(driver);
		ctx.Register(CtxUser);
		Assert.equals("CtxUser", ctx.GetTableName(CtxUser));
	}

	function testRegister_Chaining_RegistersMultipleTables() {
		final ctx = new DatabaseContext(driver).Register(CtxUser, "Users").Register(CtxOrder, "Orders");
		Assert.equals(2, ctx.Tables.length);
	}

	// ---- Query Methods ----

	function testQuery_ReturnsQueryForRegisteredTable() {
		final ctx = new DatabaseContext(driver).Register(CtxUser, "Users");
		final query = ctx.Query(CtxUser);
		Assert.notNull(query);
	}

	function testQuery_ThrowsForUnregisteredTable() {
		final ctx = new DatabaseContext(driver);
		Assert.throws(() -> ctx.Query(CtxUser));
	}

	function testFrom_CreatesSelectQuery() {
		final ctx = new DatabaseContext(driver).Register(CtxUser, "Users");
		final selectQuery = ctx.From(CtxUser);
		Assert.notNull(selectQuery);
	}

	function testUpdate_CreatesUpdateQuery() {
		final ctx = new DatabaseContext(driver).Register(CtxUser, "Users");
		final updateQuery = ctx.Update(CtxUser);
		Assert.notNull(updateQuery);
	}

	function testDelete_CreatesDeleteQuery() {
		final ctx = new DatabaseContext(driver).Register(CtxUser, "Users");
		final deleteQuery = ctx.Delete(CtxUser);
		Assert.notNull(deleteQuery);
	}

	// ---- ToSql ----

	function testToSql_SelectExpression_UsesDriver() {
		final ctx = new DatabaseContext(driver).Register(CtxUser, "Users");

		final expression = ctx.From(CtxUser).Select(u -> {id: u.id, name: u.name}).ToExpression();

		final sql = ctx.ToSql(expression);

		Assert.contains("SELECT", sql);
		Assert.contains("Users", sql);
	}

	function testGetCreateTableSql_GeneratesCorrectSql() {
		final ctx = new DatabaseContext(driver).Register(CtxUser, BuildTestUserDefinition("Users"));

		final sql = ctx.GetCreateTableSql(CtxUser);

		Assert.contains("CREATE TABLE", sql);
		Assert.contains("Users", sql);
		Assert.contains("id", sql);
		Assert.contains("name", sql);
	}

	function testGetCreateTableSql_WithIfNotExists_IncludesClause() {
		final ctx = new DatabaseContext(driver).Register(CtxUser, "Users");
		final sql = ctx.GetCreateTableSql(CtxUser, true);
		Assert.contains("IF NOT EXISTS", sql);
	}

	function testGetCreateAllTablesSql_GeneratesSqlForAllTables() {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(CtxUser, "Users").Column(u -> u.id);
		snapshot.DefineTable(CtxOrder, "Orders").Column(o -> o.id);

		final ctx = new DatabaseContext(driver)
			.Register(CtxUser, snapshot.GetTable(CtxUser))
			.Register(CtxOrder, snapshot.GetTable(CtxOrder));

		final sqls = ctx.GetCreateAllTablesSql();

		Assert.equals(2, sqls.length);
		Assert.isTrue(sqls.any(s -> s.indexOf("Users") >= 0));
		Assert.isTrue(sqls.any(s -> s.indexOf("Orders") >= 0));
	}

	// ---- Diff ----

	function testDiff_NewTable_ReturnsCreateTable() {
		final oldCtx = new DatabaseContext(driver).Register(CtxUser, "Users");

		final orderTable = new SchemaSnapshot();
		orderTable.DefineTable(CtxOrder, "Orders").Column(o -> o.id);

		final newCtx = new DatabaseContext(driver).Register(CtxUser, "Users").Register(CtxOrder, orderTable.GetTable(CtxOrder));

		final changes = newCtx.Diff(oldCtx);

		Assert.single(changes.ofType(CreateTableExpression));
		final create = changes.ofType(CreateTableExpression)[0];
		Assert.equals("Orders", create.TableName);
	}

	function testDiff_DroppedTable_ReturnsDropTable() {
		final oldCtx = new DatabaseContext(driver).Register(CtxUser, "Users").Register(CtxOrder, "Orders");
		final newCtx = new DatabaseContext(driver).Register(CtxUser, "Users");

		final changes = newCtx.Diff(oldCtx);

		Assert.single(changes.ofType(DropTableExpression));
		final drop = changes.ofType(DropTableExpression)[0];
		Assert.equals("Orders", drop.TableName);
	}

	function testDiff_ModifiedTable_ReturnsColumnChanges() {
		final oldSnap = new SchemaSnapshot();
		oldSnap.DefineTable(CtxUser, "Users")
			.Column(u -> u.id)
			.Column(u -> u.name).MaxLength(50);

		final newSnap = new SchemaSnapshot();
		newSnap.DefineTable(CtxUser, "Users")
			.Column(u -> u.id)
			.Column(u -> u.name).MaxLength(100)
			.Column(u -> u.email).MaxLength(200);

		final oldCtx = new DatabaseContext(driver).Register(CtxUser, oldSnap.GetTable(CtxUser));
		final newCtx = new DatabaseContext(driver).Register(CtxUser, newSnap.GetTable(CtxUser));

		final changes = newCtx.Diff(oldCtx);

		Assert.single(changes.ofType(AddColumnExpression));
		Assert.single(changes.ofType(AlterColumnExpression));
	}

	// ---- WithDriver ----

	function testWithDriver_CreatesNewContextWithSameTables() {
		final sqliteDriver = new SqlTranslator();
		final postgresDriver = new SqlTranslator();

		final ctx = new DatabaseContext(sqliteDriver).Register(CtxUser, "Users").Register(CtxOrder, "Orders");

		final newCtx = ctx.WithDriver(postgresDriver);

		Assert.isTrue(postgresDriver == newCtx.Driver);
		Assert.equals(2, newCtx.Tables.length);
		Assert.equals("Users", newCtx.GetTableName(CtxUser));
	}

	static function BuildTestUserDefinition(tableName:String):DatabaseTableDefinition {
		final snapshot = new SchemaSnapshot();
		snapshot.DefineTable(CtxUser, tableName)
			.Column(u -> u.id).AutoIncrement()
			.Column(u -> u.name).MaxLength(100).NotNull()
			.Column(u -> u.id).PrimaryKey(null, false, 'PK_$tableName');
		return snapshot.GetTable(CtxUser);
	}
}

private class CtxUser {
	public var id:Int = 0;
	public var name:String = "";
	public var email:Null<String>;

	public function new() {}
}

private class CtxOrder {
	public var id:Int = 0;
	public var userId:Int = 0;
	public var amount:Decimal = 0;

	public function new() {}
}
