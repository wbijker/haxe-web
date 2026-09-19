package suites;

import codequery.DbTable;
import codequery.DbView;
import codequery.migrations.DatabaseSchema;
import codequery.migrations.SchemaBuilder;
import codequery.migrations.SchemaChange;
import codequery.migrations.SchemaDiff;
import codequery.migrations.SchemaSnapshot;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("books")
class AddViewBook {
	public var id:Int = 0;

	@columnNullable(false)
	public var title:String = "";

	public var price:Float = 0;

	public function new() {}
}

/** C# adds the view in `Configure(schema)` with `AddView(name, query)`; here it is a member with a name. */
class AddViewShop {
	public final Books:DbTable<AddViewBook> = DbTable.of();

	public final Expensive:DbView<AddViewBook>;

	public function new() {
		Expensive = DbView.of(Books.From().Where(b -> b.price > 20), "v_expensive_books");
	}
}

/**
	`AddViewTests.cs`: the typed query is rendered into a `CREATE VIEW` statement, honours the
	materialized flag, and takes part in the migration diff and the snapshot.
**/
class AddViewTests extends TestCase {
	static function CreateShop():DatabaseSchema {
		return SchemaBuilder.Of(new AddViewShop());
	}

	function testAddView_RegistersViewRoutineFromTypedQuery() {
		final shop = CreateShop();

		final view = Assert.single(shop.Views);
		Assert.equals("v_expensive_books", view.Name);
		// SQLite renders an idempotent DROP-then-CREATE in C#; the port's dialect replaces in place.
		final body = new SqlTranslator().ToDdl(CreateView(view));
		Assert.startsWith("CREATE OR REPLACE VIEW v_expensive_books AS", body);
		Assert.contains("FROM books", body);
		Assert.contains("price > 20", body);
	}

	function testAddedView_ShowsUpInMigrationDiff() {
		final shop = CreateShop();

		final diff = SchemaDiff.Between(DatabaseSchema.Empty(), shop);

		Assert.isTrue(diff.length > 0);
		Assert.isTrue(diff.filter(c -> c.match(CreateView(_))).length == 1);
		switch diff.filter(c -> c.match(CreateView(_)))[0] {
			case CreateView(view): Assert.equals("v_expensive_books", view.Name);
			case _: Assert.fail("Expected the view to be created");
		}
	}

	function testView_RoundTripsThroughJsonSnapshot() {
		final shop = CreateShop();

		final yaml = SchemaSnapshot.ToYaml(shop);
		final back = SchemaSnapshot.FromYaml(yaml);

		final view = Assert.single(back.Views);
		Assert.equals("v_expensive_books", view.Name);
		// A round-tripped snapshot is identical, so re-diffing reports no changes.
		Assert.empty(SchemaDiff.Between(shop, back));
	}

	// --- Driver-level CREATE VIEW rendering ---------------------------------------------------

	static final Select = "SELECT *\nFROM t";

	function testSqlite_RendersDropThenCreateView_ForIdempotentReplace() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testSqlite_MaterializedThrows() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testPostgres_RendersOrReplaceView() {
		final sql = new SqlTranslator().BuildCreateViewSql("v", Select, false);
		Assert.startsWith("CREATE OR REPLACE VIEW v AS", sql);
	}

	function testPostgres_RendersMaterializedView() {
		final sql = new SqlTranslator().BuildCreateViewSql("v", Select, true);
		Assert.startsWith("CREATE MATERIALIZED VIEW v AS", sql);
	}

	function testMySql_RendersOrReplaceView_MaterializedThrows() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testSqlServer_RendersCreateOrAlterView_MaterializedThrows() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}
}
