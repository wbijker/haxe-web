package suites;

import codequery.DbTable;
import codequery.DbView;
import codequery.QualifiedTableName;
import codequery.Query;
import codequery.migrations.DatabaseSchema;
import codequery.migrations.SchemaBuilder;
import codequery.migrations.SchemaChange;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("gadgets")
class InlineGadget {
	public var id:Int = 0;
	public var name:String = "";
	public var price:Float = 0;

	public function new() {}
}

/** Named by the row type — its `@tableName`, so the row type reads from the view. */
@tableName("v_pricey_gadgets")
class InlinePriceyGadget {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

/** Named by the constructor. */
class InlineCheapGadget {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

class InlineShop {
	public final Gadgets:DbTable<InlineGadget> = DbTable.of();

	public final Pricey:DbView<InlinePriceyGadget>;
	public final Cheap:DbView<InlineCheapGadget>;

	public function new() {
		Pricey = DbView.of(Gadgets.From().Where(g -> g.price > 100).Select(g -> {id: g.id, name: g.name}));
		Cheap = DbView.of(Gadgets.From().Where(g -> g.price < 10).Select(g -> {id: g.id, name: g.name}),
			"v_cheap_gadgets");
	}
}

/** A view declared without the query that defines it. */
class InlineBareView extends DbView<InlineGadget> {
	public function new() {
		super(new QualifiedTableName("bare"));
	}
}

/**
	`InlineViewTests.cs`: `DbView` constructed with the query it selects — a view declared where it
	is used, with no class of its own. The C# snapshot carries the view's body as SQLite's
	`DROP VIEW … ; CREATE VIEW …`, pretty-printed; the port carries the query and renders the
	`CREATE` in its own dialect when asked, which is what is checked here.
**/
class InlineViewTests extends TestCase {
	static function NewShop():InlineShop {
		return new InlineShop();
	}

	static function ViewBody(db:InlineShop, name:String):String {
		final view = SchemaBuilder.Of(db).GetView(name);
		Assert.notNull(view, 'No view named $name');
		return new SqlTranslator().ToDdl(CreateView(view));
	}

	function testDefinition_IsRenderedIntoACreateView() {
		final db = NewShop();

		final body = ViewBody(db, "v_pricey_gadgets");

		Assert.equals(
			"CREATE OR REPLACE VIEW v_pricey_gadgets AS\n"
			+ "SELECT t0.id AS id, t0.name AS name FROM gadgets AS t0 WHERE t0.price > 100",
			body);
	}

	function testUnnamedView_TakesTheRowTypesName() {
		final db = NewShop();

		Assert.equals("v_pricey_gadgets", db.Pricey.ViewName);
		Assert.equals("v_pricey_gadgets", db.Pricey.From().ToExpression().selectTableName());
	}

	function testConstructorName_NamesTheView() {
		final db = NewShop();

		Assert.equals("v_cheap_gadgets", db.Cheap.ViewName);
		Assert.contains("CREATE OR REPLACE VIEW v_cheap_gadgets AS", ViewBody(db, "v_cheap_gadgets"));
	}

	function testMemberAttribute_NamesTheView() {
		Assert.skip("DbViewName: member attribute not in this port (the name is given to DbView.of)");
	}

	function testConstructorName_WinsOverTheMemberAttribute() {
		Assert.skip("DbViewName: member attribute not in this port (the name is given to DbView.of)");
	}

	function testViewMember_IsQueryable_AndSelectsFromTheView() {
		final db = NewShop();

		Assert.equals("v_cheap_gadgets", db.Cheap.From().ToExpression().selectTableName());
	}

	function testViewMember_IsFreshPerAccess_SoFiltersDoNotAccumulate() {
		final db = NewShop();

		db.Cheap.From().Where(g -> g.id > 5);

		Assert.isNull(db.Cheap.From().ToExpression().Where);
	}

	function testDefinition_IsTheQueryTheViewWasConstructedWith() {
		final db = NewShop();

		final definition = db.Pricey.Defined();

		// The definition reads the table, not the view it defines.
		Assert.equals("gadgets", definition.selectTableName());
		definition.whereClause().comparison("price", GreaterThan, 100);
	}

	function testSubclassWithoutADefinition_Explains_HowToGiveItOne() {
		final error = Assert.throwsMessage(() -> new InlineBareView().Defined());

		Assert.contains("has no definition", error);
	}
}
