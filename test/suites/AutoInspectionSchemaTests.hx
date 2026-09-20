package suites;

import codequery.DbSchema;
import codequery.DbTable;
import codequery.execution.DatabaseConfiguration;
import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/**
	`AutoInspectionSchemaTests.cs` — a `DbSchema` declaring only table members has its tables
	inspected automatically from the entity types, and `Configure` can augment them.
**/
class AutoInspectionSchemaTests extends TestCase {
	static function CreateShop():AiShop {
		return new AiShop(new DatabaseConfiguration(new SqlTranslator()));
	}

	function testTableProperties_AreCreatedAutomatically() {
		final shop = CreateShop();

		Assert.notNull(shop.Authors);
		Assert.notNull(shop.Books);
		Assert.equals("authors", shop.Authors.TableName);
		Assert.equals("books", shop.Books.TableName);
	}

	function testEnsureBuilt_InspectsEntitiesFromAttributes() {
		final shop = CreateShop();
		shop.EnsureBuilt();

		final authors = shop.Schema.GetTable(AiAuthor);
		Assert.equals("authors", authors.TableName);
		Assert.equals(["id", "name", "country"], authors.Columns.map(c -> c.Name));

		// @columnNullable(false) overrides the reference-type default.
		Assert.isFalse(authors.Columns.single(c -> c.Name == "name").IsNullable);
		Assert.isTrue(authors.Columns.single(c -> c.Name == "country").IsNullable);

		// "id" convention → primary key, auto-increment.
		Assert.isTrue(authors.Constraints.ofType(DatabasePrimaryKeyConstraint).any(pk -> pk.Columns.length == 1 && pk.Columns[0] == "id"));
		Assert.isTrue(authors.Columns.single(c -> c.Name == "id").IsAutoIncrement);
	}

	function testColumnMaxLength_IsHonored() {
		final shop = CreateShop();
		shop.EnsureBuilt();

		final title = shop.Schema.GetTable(AiBook).Columns.single(c -> c.Name == "title");
		Assert.equals(500, title.MaxLength);
	}

	function testColumnForeignKey_ResolvesReferencedTableByEntity() {
		final shop = CreateShop();
		shop.EnsureBuilt();

		final fk = shop.Schema.GetTable(AiBook).Constraints.ofType(DatabaseForeignKeyConstraint).single();
		Assert.equals(["authorId"], fk.Columns);
		Assert.equals("authors", fk.ReferencedTable);
		Assert.equals(["id"], fk.ReferencedColumns);
	}

	function testConfigure_AugmentsInspectedSchema() {
		final shop = CreateShop();
		shop.EnsureBuilt();

		final check = shop.Schema.GetTable(AiBook).Constraints.ofType(DatabaseCheckConstraint).single();
		Assert.equals("CK_books_title", check.Name);
	}

	function testEnsureBuilt_IsIdempotent() {
		final shop = CreateShop();
		shop.EnsureBuilt();
		shop.EnsureBuilt();

		// No duplicate tables from repeated builds.
		Assert.single(shop.Schema.Tables.filter(t -> t.TableName == "books"));
		Assert.single(shop.Schema.GetTable(AiBook).Constraints.ofType(DatabaseCheckConstraint));
	}
}

@tableName("authors")
private class AiAuthor {
	public var id:Int = 0;

	@columnNullable(false)
	public var name:String = "";

	public var country:Null<String>;

	public function new() {}
}

@tableName("books")
private class AiBook {
	public var id:Int = 0;

	@columnMaxLength(500)
	public var title:String = "";

	@columnForeignKey("AiAuthor")
	public var authorId:Int = 0;

	public function new() {}
}

private class AiShop extends DbSchema {
	public final Authors:DbTable<AiAuthor> = DbTable.of();
	public final Books:DbTable<AiBook> = DbTable.of();

	public function new(configuration:DatabaseConfiguration) {
		super(configuration);
	}

	override function Configure(schema:SchemaSnapshot):Void {
		schema.Entity(AiBook).Check("CK_books_title", b -> b.title != null);
	}
}
