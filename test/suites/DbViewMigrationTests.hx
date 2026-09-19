package suites;

import codequery.DbTable;
import codequery.DbView;
import codequery.QualifiedTableName;
import codequery.Query;
import codequery.migrations.DatabaseSchema;
import codequery.migrations.DatabaseViewDefinition;
import codequery.migrations.DbMigrationStrategy;
import codequery.migrations.SchemaBuilder;
import codequery.migrations.SchemaChange;
import codequery.migrations.SchemaDiff;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("widgets")
class ViewWidget {
	public var id:Int = 0;
	public var price:Float = 0;

	public function new() {}
}

/** The strategy comes off the view class. */
@dbMigration("DropCascadeThenCreate")
class PriceyWidgets extends DbView<ViewWidget> {
	public function new() {
		super(new QualifiedTableName("v_pricey"), Query.select(ViewWidget).Where(w -> w.price > 100).ToExpression());
	}
}

class CheapWidgets extends DbView<ViewWidget> {
	public function new() {
		super(new QualifiedTableName("v_cheap"), Query.select(ViewWidget).Where(w -> w.price <= 100).ToExpression());
	}
}

class ViewShopDb {
	public final Widgets:DbTable<ViewWidget> = DbTable.of();

	/** The strategy comes off the view class. */
	public final Pricey:DbView<ViewWidget> = new PriceyWidgets();

	/** And here off the member, which is the only place an inline view can carry one. */
	@dbMigration("DropThenCreate")
	public final Cheap:DbView<ViewWidget> = new CheapWidgets();

	/** No strategy declared: replaced in place. */
	public final All:DbView<ViewWidget> = DbView.of(Query.select(ViewWidget), "v_all");

	// C# also declares `Restored`, migrated by DropCascadeThenRestore — PostgreSQL's catalogue is
	// what puts the dependants back, and the port's dialect has no spelling for it.

	public function new() {}
}

/**
	`DbViewMigrationTests.cs`: `@dbMigration` — how a changed view is put into the database. The
	choice is part of the generated statement, so it travels into the snapshot and a change to it
	re-migrates the view. The C# expects PostgreSQL's quoted spelling; the port renders one plain
	dialect, and the other dialects' spellings stand aside.
**/
class DbViewMigrationTests extends TestCase {
	static final Select = "SELECT id FROM widgets";

	// ---- what each strategy renders ------------------------------------------------------------------

	function testByDefault_TheViewIsReplacedInPlace() {
		Assert.equals(
			'CREATE OR REPLACE VIEW v AS\n$Select',
			new SqlTranslator().BuildCreateViewSql("v", Select, false));
	}

	function testDropThenCreate_DropsFirst() {
		Assert.equals(
			'DROP VIEW IF EXISTS v;\nCREATE VIEW v AS\n$Select',
			new SqlTranslator().BuildCreateViewSql("v", Select, false, DropThenCreate));
	}

	function testDropCascadeThenCreate_TakesItsDependantsWithIt() {
		Assert.equals(
			'DROP VIEW IF EXISTS v CASCADE;\nCREATE VIEW v AS\n$Select',
			new SqlTranslator().BuildCreateViewSql("v", Select, false, DropCascadeThenCreate));
	}

	/** A materialized view has no replace form at all, so dropping first is the only way to change one. */
	function testAMaterializedView_IsDroppedByItsOwnKeyword() {
		Assert.equals(
			'DROP MATERIALIZED VIEW IF EXISTS mv CASCADE;\nCREATE MATERIALIZED VIEW mv AS\n$Select',
			new SqlTranslator().BuildCreateViewSql("mv", Select, true, DropCascadeThenCreate));
	}

	// ---- the other dialects --------------------------------------------------------------------------

	function testSqlServer_ReplacesWithCreateOrAlter_AndDropsWhenAsked() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testTheDialectsWithoutCascade_RefuseIt() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port (nor SQLite's or MySQL's)");
	}

	function testSqlite_DropsFirstEitherWay() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	// ---- create only when absent ---------------------------------------------------------------------

	/** The port's dialect, like SQLite, has the form built in. */
	function testCreateIfAbsent_Sqlite_SaysItDirectly() {
		Assert.equals(
			'CREATE VIEW IF NOT EXISTS v AS\n$Select',
			new SqlTranslator().BuildCreateViewSql("v", Select, false, CreateIfAbsent));
	}

	function testCreateIfAbsent_Postgres_WritesTheCheckOut() {
		Assert.skip("PostgresSqlDriver: the to_regclass DO block is PostgreSQL's own spelling");
	}

	function testCreateIfAbsent_SqlServer_GuardsWithObjectId() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testCreateIfAbsent_MySql_IsRefused() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	// ---- build beside, then rename into place ----------------------------------------------------------

	function testRenameSwap_BuildsUnderAStagingNameFirst() {
		Assert.equals(
			"DROP VIEW IF EXISTS v__new;\n"
			+ 'CREATE VIEW v__new AS\n$Select;\n'
			+ "DROP VIEW IF EXISTS v;\n"
			+ "ALTER VIEW v__new RENAME TO v",
			new SqlTranslator().BuildCreateViewSql("v", Select, false, RenameSwap));
	}

	function testRenameSwap_MySql_RenamesTheTable() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testRenameSwap_SqlServer_UsesSpRename() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testRenameSwap_Sqlite_IsRefused() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	// ---- cascade, then put back what it took -----------------------------------------------------------

	function testDropCascadeThenRestore_SavesTheDependantsFirst() {
		Assert.skip("PostgresSqlDriver: DropCascadeThenRestore reads pg_catalog, PostgreSQL's own");
	}

	function testDropCascadeThenRestore_AMaterializedView_UsesItsOwnKeyword() {
		Assert.skip("PostgresSqlDriver: DropCascadeThenRestore reads pg_catalog, PostgreSQL's own");
	}

	/** It needs both a cascading drop and a way to read a view's definition back; the port's dialect has neither. */
	function testDropCascadeThenRestore_IsPostgresOnly() {
		Assert.throws(() -> new SqlTranslator().BuildCreateViewSql("v", Select, false, DropCascadeThenRestore));
	}

	// ---- the attribute on a schema -------------------------------------------------------------------

	static function Snapshot():DatabaseSchema {
		return SchemaBuilder.Of(new ViewShopDb());
	}

	static function Body(snapshot:DatabaseSchema, name:String):String {
		final view = snapshot.View(name);
		Assert.notNull(view, 'No view named $name');
		return new SqlTranslator().ToDdl(CreateView(view));
	}

	function testTheStrategy_IsPartOfTheGeneratedView() {
		final snapshot = Snapshot();

		Assert.startsWith("DROP VIEW IF EXISTS v_pricey CASCADE;\nCREATE VIEW", Body(snapshot, "v_pricey"));
		Assert.startsWith("DROP VIEW IF EXISTS v_cheap;\nCREATE VIEW", Body(snapshot, "v_cheap"));
		Assert.startsWith("CREATE OR REPLACE VIEW v_all", Body(snapshot, "v_all"));
		// C#'s fourth, `v_restored`, is DropCascadeThenRestore — PostgreSQL only, and not here.
	}

	/** The migration runs the stored definition, so what the snapshot says is what the database gets. */
	function testTheMigrationAppliesIt() {
		final operations = SchemaDiff.Between(DatabaseSchema.Empty(), Snapshot());

		final translator = new SqlTranslator();
		final sql = [for (change in operations) if (change.match(CreateView(_))) translator.ToDdl(change)];

		Assert.isTrue(sql.filter(s -> StringTools.startsWith(s, "DROP VIEW IF EXISTS v_pricey CASCADE;")).length == 1);
	}

	/** Changing only the strategy is a change to the view, so the next migration recreates it. */
	function testChangingTheStrategy_ReMigratesTheView() {
		final replaced = new DatabaseSchema([], null, 1, [new DatabaseViewDefinition("v_pricey", Select, false, CreateOrReplace)]);
		final dropped = new DatabaseSchema([], null, 1, [new DatabaseViewDefinition("v_pricey", Select, false, DropCascadeThenCreate)]);

		final diff = SchemaDiff.Between(replaced, dropped);

		switch Assert.single(diff) {
			case AlterView(_, to): Assert.equals("v_pricey", to.Name);
			case other: Assert.fail('Expected the view to be altered, got $other');
		}
	}
}
