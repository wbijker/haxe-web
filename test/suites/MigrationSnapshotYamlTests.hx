package suites;

import codequery.migrations.*;
import codequery.migrations.DatabaseColumnType;
import codequery.migrations.DatabaseIndexDefinition;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`MigrationSnapshotYamlTests.cs`: each migration stores the full schema state after it as YAML,
	canonically ordered so equivalent schemas serialize identically and round-trip losslessly.
**/
class MigrationSnapshotYamlTests extends TestCase {
	static function ToYaml(s:SchemaSnapshot):String {
		return SnapshotSerializer.Serialize(SchemaSnapshotDocument.FromModel(SchemaCanonicalizer.Canonical(s)));
	}

	static function FromYaml(yaml:String):SchemaSnapshot {
		return SchemaSnapshot.FromDatabaseSchema(SnapshotSerializer.Deserialize(yaml).ToModel());
	}

	static function RichSchema():SchemaSnapshot {
		final s = new SchemaSnapshot();
		s.AddTable("authors")
			.AddColumn("Id", DatabaseColumnType.Int, false, true)
			.AddColumn("Name", DatabaseColumnType.VarChar, false, false, 255)
			.PrimaryKey("PK_authors", ["Id"]);
		s.AddTable("books")
			.AddColumn("Id", DatabaseColumnType.Int, false, true)
			.AddColumn("AuthorId", DatabaseColumnType.Int, false)
			.AddColumn("Rating", DatabaseColumnType.Int, false)
			.PrimaryKey("PK_books", ["Id"])
			.ForeignKey("FK_books_AuthorId", ["AuthorId"], "authors", ["Id"])
			.Check("CK_books_rating", "Rating >= 1 AND Rating <= 5")
			.Index("IX_books_AuthorId", ["AuthorId"]);
		return s;
	}

	function testSnapshot_RoundTripsThroughYaml() {
		final original = RichSchema();
		final yaml = ToYaml(original);
		final reloaded = FromYaml(yaml);
		// Same structure back out, and re-serializing is byte-stable.
		Assert.equals(SchemaCanonicalizer.Fingerprint(original), SchemaCanonicalizer.Fingerprint(reloaded));
		Assert.equals(yaml, ToYaml(reloaded));
	}

	function testSnapshot_StoresTheWholeSchema_NotJustAChange() {
		final yaml = ToYaml(RichSchema());
		Assert.contains("tables:", yaml);
		Assert.contains("name: authors", yaml);
		Assert.contains("name: books", yaml);
	}

	function testSnapshot_SerializesDeterministically_RegardlessOfTableOrder() {
		final a = new SchemaSnapshot();
		a.AddTable("books").AddColumn("Id", DatabaseColumnType.Int, false);
		a.AddTable("authors").AddColumn("Id", DatabaseColumnType.Int, false);
		final b = new SchemaSnapshot();
		b.AddTable("authors").AddColumn("Id", DatabaseColumnType.Int, false);
		b.AddTable("books").AddColumn("Id", DatabaseColumnType.Int, false);
		Assert.equals(ToYaml(a), ToYaml(b));
	}

	function testSnapshot_EmitsMultilineSqlAsAReadableLiteralBlock() {
		final s = RichSchema();
		s.View("v_authors", "SELECT *\nFROM authors\nWHERE Name IS NOT NULL");
		final yaml = ToYaml(s);
		Assert.contains("|", yaml);
		Assert.contains("FROM authors", yaml);
	}

	function testTwoSnapshots_DiffToTheChangeBetweenThem() {
		final before = new SchemaSnapshot();
		before.AddTable("authors")
			.AddColumn("Id", DatabaseColumnType.Int, false, true)
			.AddColumn("Name", DatabaseColumnType.VarChar, false, false, 255)
			.PrimaryKey("PK_authors", ["Id"]);

		final after = FromYaml(ToYaml(before));
		after.GetTable("authors").AddColumn("Email", DatabaseColumnType.VarChar, true, false, 255);

		// Reading two snapshots and diffing them is exactly what the rebuilder does.
		final diff = SchemaDiff.Create(FromYaml(ToYaml(before)), FromYaml(ToYaml(after)));
		final modified = Assert.single(diff.ModifiedTables);
		final added = Assert.single(modified.AddedColumns);
		Assert.equals("Email", added.Name);
	}

	function testSnapshot_KeepsTheIndexMethodAndIncludedColumns() {
		final s = new SchemaSnapshot();
		final t = s.AddTable("part")
			.AddColumn("Id", DatabaseColumnType.Int, false, true)
			.AddColumn("Characteristics", DatabaseColumnType.Json)
			.AddColumn("Code", DatabaseColumnType.VarChar, true, false, 50)
			.AddColumn("Name", DatabaseColumnType.VarChar, true, false, 200)
			.IndexOver("IX_part_Characteristics_gin", [new DatabaseIndexColumn("Characteristics")], false, false, null, "gin");
		final covering = new DatabaseIndexDefinition("IX_part_Code", [new DatabaseIndexColumn("Code")]);
		covering.IncludeColumns = ["Name"];
		t.Indexes.push(covering);

		final yaml = ToYaml(s);
		Assert.contains("method: gin", yaml);

		final reloaded = FromYaml(yaml);
		final gin = Assert.single([for (i in reloaded.GetTable("part").Indexes) if (i.Name == "IX_part_Characteristics_gin") i]);
		Assert.equals("gin", gin.Method);
		Assert.equals(["Name"], Assert.single([for (i in reloaded.GetTable("part").Indexes) if (i.Name == "IX_part_Code") i]).IncludeColumns);

		// And so the schema diffs clean against itself — no perpetual drop/create of the same index.
		Assert.isFalse(SchemaDiff.Create(s, reloaded).HasChanges);
	}
}
