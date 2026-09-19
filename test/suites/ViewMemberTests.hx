package suites;

import codequery.DbTable;
import codequery.DbView;
import codequery.migrations.SchemaBuilder;
import codequery.migrations.SchemaChange;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("novels")
class ViewMemberNovel {
	public var id:Int = 0;
	public var title:String = "";
	public var price:Float = 0;

	public function new() {}
}

class ViewMemberExpensiveNovel {
	public var id:Int = 0;
	public var title:String = "";

	public function new() {}
}

class ViewMemberShop {
	public final Novels:DbTable<ViewMemberNovel> = DbTable.of();

	// The member has the schema's tables in hand, so the view is written where it is declared.
	public final ExpensiveNovels:DbView<ViewMemberExpensiveNovel>;

	public function new() {
		ExpensiveNovels = DbView.of(
			Novels.From()
				.Where(n -> n.price > 20)
				.Select(n -> {id: n.id, title: n.title}),
			"v_expensive_novels");
	}
}

/**
	`ViewMemberTests.cs`: a view declared as a schema member: the member builds it from the schema's
	own tables, the schema registers it as a `CREATE VIEW`, and the member doubles as a query over
	the view itself.
**/
class ViewMemberTests extends TestCase {
	static function NewShop():ViewMemberShop {
		return new ViewMemberShop();
	}

	static function Body(db:ViewMemberShop):String {
		final view = Assert.single(SchemaBuilder.Of(db).Views);
		return new SqlTranslator().ToDdl(CreateView(view));
	}

	function testDefinition_IsRenderedIntoACreateView() {
		final db = NewShop();

		final view = Assert.single(SchemaBuilder.Of(db).Views);

		Assert.equals("v_expensive_novels", view.Name);
		final body = Body(db);
		Assert.contains("CREATE OR REPLACE VIEW v_expensive_novels AS", body);
		Assert.contains("FROM novels", body);
		Assert.contains("price > 20", body);
	}

	function testViewBody_IsPrettyPrinted() {
		// The C# body is SQLite's drop-then-create, pretty-printed over several lines; the port
		// writes the statement on a line of its own and the query on the next.
		final db = NewShop();

		Assert.equals(
			"CREATE OR REPLACE VIEW v_expensive_novels AS\n"
			+ "SELECT t0.id AS id, t0.title AS title FROM novels AS t0 WHERE t0.price > 20",
			Body(db));
	}

	function testViewMember_IsQueryable_AndSelectsFromTheView() {
		final db = NewShop();

		Assert.equals("v_expensive_novels", db.ExpensiveNovels.From().ToExpression().selectTableName());
	}

	function testViewMember_IsFreshPerAccess_SoFiltersDoNotAccumulate() {
		final db = NewShop();

		db.ExpensiveNovels.From().Where(n -> n.id > 5);

		Assert.isNull(db.ExpensiveNovels.From().ToExpression().Where);
	}
}
