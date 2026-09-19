package suites;

import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("form")
class Form {
	public var id:Int = 0;
	public var schemaJson:String = "";
	public var title:String = "";
	public var body:String = "";

	public function new() {}
}

/** `IndexTypeTests.cs`: how an index stores what it indexes, said on the column — `IndexUsing(Gin)`. */
class IndexTypeTests extends TestCase {
	static function IndexSql(definition:DatabaseTableDefinition):Array<String> {
		return [for (i in definition.Indexes) new SqlTranslator().ToSql(i.ToCreateIndexExpression(definition.Name, definition.Schema))];
	}

	static function Builder():EntityTableBuilder<Form> {
		final snapshot = new SchemaSnapshot();
		final definition = SchemaInspector.FromType(Form);
		snapshot.Tables.push(definition);
		return snapshot.Entity(Form);
	}

	function testGin_IsRenderedAsUsingGin() {
		final t = Builder();
		t.Column(f -> f.schemaJson).IndexUsing(Gin);
		Assert.isTrue(IndexSql(t.Definition).indexOf("CREATE INDEX IX_form_schemaJson ON form USING gin (schemaJson)") >= 0);
	}

	function testATypeCanBeNamed() {
		final t = Builder();
		t.Column(f -> f.schemaJson).IndexUsing(Gin, "IX_form_schema");
		Assert.isTrue(Lambda.exists(IndexSql(t.Definition), s -> s.indexOf("IX_form_schema") >= 0 && s.indexOf("USING gin") >= 0));
	}

	function testBTree_IsTheDefault_AndGoesUnsaid() {
		final t = Builder();
		t.Column(f -> f.title).Index();
		Assert.isTrue(IndexSql(t.Definition).indexOf("CREATE INDEX IX_form_title ON form (title)") >= 0);
	}

	function testACompositeCanCarryOneToo() {
		final t = Builder();
		t.Column(f -> f.title).And(f -> f.body).IndexUsing(Gin, "IX_form_text");
		Assert.isTrue(IndexSql(t.Definition).indexOf("CREATE INDEX IX_form_text ON form USING gin (title, body)") >= 0);
	}
}
