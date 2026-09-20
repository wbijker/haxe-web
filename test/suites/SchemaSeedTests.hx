package suites;

import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

class SeedAuthor {
	public var id:Int = 0;
	public var name:String = "";
	public var country:Null<String>;

	public function new(id:Int = 0, name:String = "", ?country:String) {
		this.id = id;
		this.name = name;
		this.country = country;
	}
}

/** `SchemaSeedTests.cs`. */
class SchemaSeedTests extends TestCase {
	static function Make(authors:Array<SeedAuthor>):SchemaSnapshot {
		final s = new SchemaSnapshot();
		s.DefineTable(SeedAuthor, "authors")
			.Column(a -> a.id)
			.Column(a -> a.name).MaxLength(255).NotNull()
			.Column(a -> a.country).MaxLength(255)
			.Column(a -> a.id).PrimaryKey(ServerGenerated, false, "PK_authors");
		s.Seed(SeedAuthor, authors);
		return s;
	}

	static function Sql(op:SeedDataExpression):String {
		return new SqlTranslator().ToSql(op);
	}

	function testNewRow_Inserts() {
		final diff = SchemaDiff.Create(Make([]), Make([new SeedAuthor(1, "Jane", "UK")]));
		final op = Assert.single(diff.SeedChanges);
		Assert.equals(SeedOperation.Insert, op.Operation);
		Assert.equals("INSERT INTO authors (id, name, country) VALUES (1, 'Jane', 'UK')", Sql(op));
	}

	function testChangedRecord_Updates() {
		final from = Make([new SeedAuthor(1, "Jane", "UK")]);
		final to = Make([new SeedAuthor(1, "Janet", "UK")]);
		final op = Assert.single(SchemaDiff.Create(from, to).SeedChanges);
		Assert.equals(SeedOperation.Update, op.Operation);
		Assert.equals("UPDATE authors SET name = 'Janet', country = 'UK' WHERE id = 1", Sql(op));
	}

	function testRemovedRow_Deletes() {
		final from = Make([new SeedAuthor(1, "Jane"), new SeedAuthor(2, "Mark")]);
		final to = Make([new SeedAuthor(1, "Jane")]);
		final op = Assert.single(SchemaDiff.Create(from, to).SeedChanges);
		Assert.equals(SeedOperation.Delete, op.Operation);
		Assert.equals("DELETE FROM authors WHERE id = 2", Sql(op));
	}

	function testIdenticalData_NoChange_AndSurvivesSerialization() {
		final a = Make([new SeedAuthor(1, "Jane", "UK")]);
		final b = Make([new SeedAuthor(1, "Jane", "UK")]);
		Assert.isFalse(SchemaDiff.Create(a, b).HasChanges);

		final back = SchemaSnapshot.FromDatabaseSchema(SchemaSnapshot.FromYaml(SchemaSnapshot.ToYaml(a.ToDatabaseSchema())));
		Assert.isFalse(SchemaDiff.Create(a, back).HasChanges);
		Assert.single(back.Seeds);
	}

	function testNullValues_RenderAsNull() {
		final diff = SchemaDiff.Create(Make([]), Make([new SeedAuthor(3, "Anon", null)]));
		Assert.contains("VALUES (3, 'Anon', NULL)", Sql(Assert.single(diff.SeedChanges)));
	}
}
