package suites;

import codequery.migrations.*;
import codequery.migrations.DatabaseColumnType;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DuplicateColumnDiffTests.cs`: a table cannot declare one column twice; the diff is what notices. */
class DuplicateColumnDiffTests extends TestCase {
	/** Two columns of one name, made the way it actually happens: a rename onto a name the table already has. */
	static function WithDuplicate():DatabaseTableDefinition {
		final table = new DatabaseTableDefinition("band_approver")
			.AddColumn("Id", DatabaseColumnType.Int, false)
			.AddColumn("BandId", DatabaseColumnType.Int, false)
			.AddColumn("band_id", DatabaseColumnType.Int, false);
		for (column in table.Columns) {
			if (column.Name == "BandId") {
				column.Name = "band_id";
			}
		}
		return table;
	}

	static function Plain():DatabaseTableDefinition {
		return new DatabaseTableDefinition("band_approver").AddColumn("Id", DatabaseColumnType.Int, false).AddColumn("band_id", DatabaseColumnType.Int, false);
	}

	function testADuplicateColumnNamesTheTableAndTheSide() {
		final error = Assert.throwsMessage(() -> SchemaDiff.Create(SchemaSnapshot.FromTables([WithDuplicate()]), SchemaSnapshot.FromTables([Plain()])));
		Assert.contains("band_approver", error);
		Assert.contains("band_id", error);
		Assert.contains("source", error);
	}

	function testADuplicateOnTheTargetSideSaysSo() {
		final error = Assert.throwsMessage(() -> SchemaDiff.Create(SchemaSnapshot.FromTables([Plain()]), SchemaSnapshot.FromTables([WithDuplicate()])));
		Assert.contains("target", error);
	}

	function testTablesWithoutDuplicatesDiffNormally() {
		Assert.notNull(SchemaDiff.Create(SchemaSnapshot.FromTables([Plain()]), SchemaSnapshot.FromTables([Plain()])));
	}
}
