package suites;

import codequery.DbTable;
import codequery.migrations.*;
import codequery.migrations.IMigrationPrompt;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

class HasDataAuthor {
	public var id:Int = 0;
	public var name:String = "";
	public var country:Null<String>;

	public function new(id:Int = 0, name:String = "", ?country:String) {
		this.id = id;
		this.name = name;
		this.country = country;
	}
}

class Product {
	public var id:Int = 0;
	public var name:String = "";

	public function new(id:Int = 0, name:String = "") {
		this.id = id;
		this.name = name;
	}
}

/** The realistic path: a schema class whose configuration seeds a table. */
class ShopDb {
	public final Products:DbTable<Product> = DbTable.of();

	public function new() {}

	public function Configure(schema:SchemaSnapshot):Void {
		schema.Entity(Product).HasData([new Product(1, "Widget"), new Product(2, "Gadget")]);
	}
}

class NoRenamePrompt implements IMigrationPrompt {
	public function new() {}

	public function ResolveTableRename(addedTable:String, droppedCandidates:Array<String>):Null<String> {
		return null;
	}

	public function ResolveColumnRename(tableName:String, addedColumn:String, droppedCandidates:Array<String>):Null<String> {
		return null;
	}
}

/** `HasDataTests.cs`. */
class HasDataTests extends TestCase {
	static function Sql(op:SeedDataExpression):String {
		return new SqlTranslator().ToSql(op);
	}

	/** A snapshot with the authors table and the given seed records via the fluent HasData API. */
	static function WithSeed(authors:Array<HasDataAuthor>):SchemaSnapshot {
		final s = new SchemaSnapshot();
		s.DefineTable(HasDataAuthor, "authors")
			.Column(a -> a.id).PrimaryKey(ServerGenerated, false, "PK_authors")
			.Column(a -> a.name).MaxLength(255).NotNull()
			.Column(a -> a.country).MaxLength(255)
			.Table.HasData(authors);
		return s;
	}

	// --- Fluent surface ---

	function testHasData_RecordsSeedRows_OnSnapshot() {
		final s = WithSeed([new HasDataAuthor(1, "Jane", "UK")]);
		final seed = Assert.single(s.Seeds);
		Assert.equals("authors", seed.TableName);
		Assert.equals(["id"], seed.KeyColumns);
		Assert.single(seed.Rows);
	}

	function testHasData_ParamsAndEnumerable_BothSupported() {
		final viaParams = WithSeed([new HasDataAuthor(1, "Jane"), new HasDataAuthor(2, "Mark")]);
		final list = [new HasDataAuthor(1, "Jane"), new HasDataAuthor(2, "Mark")];
		final s = new SchemaSnapshot();
		s.DefineTable(HasDataAuthor, "authors")
			.Column(a -> a.id).PrimaryKey(ServerGenerated, false, "PK_authors")
			.Column(a -> a.name).MaxLength(255).NotNull()
			.Column(a -> a.country).MaxLength(255)
			.Table.HasData(list);
		Assert.equals(Assert.single(viaParams.Seeds).Rows.length, Assert.single(s.Seeds).Rows.length);
	}

	function testHasData_ChainsFluently_ReturningBuilder() {
		final s = new SchemaSnapshot();
		final builder = s.DefineTable(HasDataAuthor, "authors")
			.Column(a -> a.id).PrimaryKey(ServerGenerated, false, "PK_authors")
			.Column(a -> a.name).MaxLength(255).NotNull()
			.Column(a -> a.country).MaxLength(255)
			.Table;
		// HasData returns the same builder so configuration can continue after it.
		Assert.isTrue(builder == builder.HasData([new HasDataAuthor(1, "Jane")]));
	}

	// --- Migration: INSERT statements ---

	function testHasData_NewRow_ProducesInsertInMigration() {
		final diff = SchemaDiff.Create(WithSeed([]), WithSeed([new HasDataAuthor(1, "Jane", "UK")]));
		final op = Assert.single(diff.SeedChanges);
		Assert.equals(SeedOperation.Insert, op.Operation);
		Assert.equals("INSERT INTO authors (id, name, country) VALUES (1, 'Jane', 'UK')", Sql(op));
	}

	function testHasData_MultipleRows_ProduceMultipleInserts() {
		final diff = SchemaDiff.Create(WithSeed([]), WithSeed([new HasDataAuthor(1, "Jane"), new HasDataAuthor(2, "Mark")]));
		Assert.equals(2, diff.SeedChanges.length);
		for (op in diff.SeedChanges) {
			Assert.equals(SeedOperation.Insert, op.Operation);
		}
	}

	function testHasData_NullValue_RendersAsNull() {
		final diff = SchemaDiff.Create(WithSeed([]), WithSeed([new HasDataAuthor(3, "Anon", null)]));
		Assert.contains("VALUES (3, 'Anon', NULL)", Sql(Assert.single(diff.SeedChanges)));
	}

	// --- Field-by-field equality ---

	function testHasData_ChangedField_ProducesUpdate() {
		final from = WithSeed([new HasDataAuthor(1, "Jane", "UK")]);
		final to = WithSeed([new HasDataAuthor(1, "Janet", "UK")]);
		final op = Assert.single(SchemaDiff.Create(from, to).SeedChanges);
		Assert.equals(SeedOperation.Update, op.Operation);
		Assert.equals("UPDATE authors SET name = 'Janet', country = 'UK' WHERE id = 1", Sql(op));
	}

	function testHasData_IdenticalFields_NoChange() {
		final a = WithSeed([new HasDataAuthor(1, "Jane", "UK")]);
		final b = WithSeed([new HasDataAuthor(1, "Jane", "UK")]);
		Assert.isFalse(SchemaDiff.Create(a, b).HasChanges);
	}

	function testHasData_RemovedRecord_ProducesDelete() {
		final from = WithSeed([new HasDataAuthor(1, "Jane"), new HasDataAuthor(2, "Mark")]);
		final to = WithSeed([new HasDataAuthor(1, "Jane")]);
		final op = Assert.single(SchemaDiff.Create(from, to).SeedChanges);
		Assert.equals(SeedOperation.Delete, op.Operation);
		Assert.equals("DELETE FROM authors WHERE id = 2", Sql(op));
	}

	// --- Realistic schema path ---

	function testHasData_InDbSchemaConfigure_IsPartOfTheMigration() {
		final db = new ShopDb();
		final schema = SchemaSnapshot.FromDatabaseSchema(SchemaBuilder.Of(db));
		db.Configure(schema);

		// Fresh database: the migration creates the table and seeds its rows.
		final ops = MigrationPlanner.Plan(SchemaDiff.Create(null, schema), new NoRenamePrompt());
		Assert.isTrue(Lambda.exists(ops, o -> Std.isOfType(o, CreateTableExpression)));
		final inserts = [for (o in ops) if (Std.isOfType(o, SeedDataExpression) && (cast o : SeedDataExpression).Operation == Insert) (cast o : SeedDataExpression)];
		Assert.equals(2, inserts.length);
		Assert.isTrue(Lambda.exists(inserts, o -> Sql(o).indexOf("'Widget'") >= 0));
		Assert.isTrue(Lambda.exists(inserts, o -> Sql(o).indexOf("'Gadget'") >= 0));
	}
}
