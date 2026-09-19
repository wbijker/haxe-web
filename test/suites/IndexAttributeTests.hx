package suites;

import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("products")
class IndexedProduct {
	public var id:Int = 0;
	@:index public var sku:String = "";
	@:index("UQ_products_email", unique = true) public var email:String = "";
	// Composite index: (categoryId ASC, createdAt DESC).
	@:index("IX_products_cat_created", order = 0) public var categoryId:Int = 0;
	@:index("IX_products_cat_created", order = 1, descending = true) public var createdAt:Date;

	public function new() {}
}

@tableName("books")
class IndexedBook {
	public var id:Int = 0;
	public var year:Int = 0;
	public var title:String = "";

	public function new() {}
}

/**
	`IndexAttributeTests.cs`: index columns defined with `@:index` and with the fluent builder,
	generated as CREATE INDEX in migrations. Identifiers are bare here, as this port writes them.
**/
class IndexAttributeTests extends TestCase {
	static function IndexSql(definition:DatabaseTableDefinition):Array<String> {
		return [
			for (e in definition.Diff(null))
				if (Std.isOfType(e, CreateIndexExpression)) new SqlTranslator().ToSql(e)
		];
	}

	function testSingleColumnIndex_FromAttribute_AutoNamed() {
		Assert.isTrue(IndexSql(SchemaInspector.FromType(IndexedProduct)).indexOf("CREATE INDEX IX_products_sku ON products (sku)") >= 0);
	}

	function testUniqueIndex_FromAttribute() {
		Assert.isTrue(IndexSql(SchemaInspector.FromType(IndexedProduct)).indexOf("CREATE UNIQUE INDEX UQ_products_email ON products (email)") >= 0);
	}

	function testCompositeIndex_FromAttribute_OrderedWithDirection() {
		Assert.isTrue(IndexSql(SchemaInspector.FromType(IndexedProduct))
			.indexOf("CREATE INDEX IX_products_cat_created ON products (categoryId, createdAt DESC)") >= 0);
	}

	function testFluentIndex_WithDirection_GeneratesDescInMigration() {
		final schema = new SchemaSnapshot();
		schema.Tables.push(SchemaInspector.FromType(IndexedBook));
		schema.Entity(IndexedBook).Column(b -> b.year).Descending().And(b -> b.title).Index("IX_books_year_title");

		final sql = Assert.single(IndexSql(schema.GetTable("books")));
		Assert.equals("CREATE INDEX IX_books_year_title ON books (year DESC, title)", sql);
	}
}
