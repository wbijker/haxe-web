package suites;

import codequery.migrations.*;
import codequery.migrations.DatabaseColumnType;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `MigrationNameGeneratorTests.cs`. */
class MigrationNameGeneratorTests extends TestCase {
	static function EmptySnapshot():SchemaSnapshot {
		return new SchemaSnapshot();
	}

	static function SnapshotWith(tables:Array<DatabaseTableDefinition>):SchemaSnapshot {
		return SchemaSnapshot.FromTables(tables);
	}

	static function Table(name:String, columns:Array<String>):DatabaseTableDefinition {
		final def = new DatabaseTableDefinition(name);
		for (c in columns) {
			def.Columns.push(DatabaseColumnDefinition.Of(c, DatabaseColumnType.Int));
		}
		return def;
	}

	static function Currency(field:String):DatabaseObjectTypeDefinition {
		return new DatabaseObjectTypeDefinition("Currency", [DatabaseColumnDefinition.Of(field, DatabaseColumnType.Double)]);
	}

	function testFirstMigration_IsInitial() {
		Assert.equals("Initial", MigrationNameGenerator.Generate(SchemaDiff.Create(null, EmptySnapshot()), true));
	}

	function testNoChanges_ReturnsNoChanges() {
		final snap = SnapshotWith([Table("Users", ["Id"])]);
		Assert.equals("No changes", MigrationNameGenerator.Generate(SchemaDiff.Create(snap, snap), false));
	}

	function testSingleColumnAdded_NamesAddColumnOnTable() {
		final diff = SchemaDiff.Create(SnapshotWith([Table("Authors", ["Id"])]), SnapshotWith([Table("Authors", ["Id", "Name"])]));
		Assert.equals("Add column Name on Authors", MigrationNameGenerator.Generate(diff, false));
	}

	function testSingleColumnDropped_NamesDropColumnOnTable() {
		final diff = SchemaDiff.Create(SnapshotWith([Table("Authors", ["Id", "Email"])]), SnapshotWith([Table("Authors", ["Id"])]));
		Assert.equals("Drop column Email on Authors", MigrationNameGenerator.Generate(diff, false));
	}

	function testSingleColumnAltered_NamesAlterColumnOnTable() {
		final from = SnapshotWith([new DatabaseTableDefinition("Authors", [DatabaseColumnDefinition.Of("UserId", DatabaseColumnType.Int)])]);
		final to = SnapshotWith([new DatabaseTableDefinition("Authors", [DatabaseColumnDefinition.Of("UserId", DatabaseColumnType.BigInt)])]);
		Assert.equals("Alter column UserId on Authors", MigrationNameGenerator.Generate(SchemaDiff.Create(from, to), false));
	}

	function testMultipleColumnChangesOnOneTable_NamesAlterTable() {
		final diff = SchemaDiff.Create(SnapshotWith([Table("Authors", ["Id"])]), SnapshotWith([Table("Authors", ["Id", "Name", "Email"])]));
		Assert.equals("Alter table Authors", MigrationNameGenerator.Generate(diff, false));
	}

	function testNewTableAdded_NamesAlterTable() {
		final diff = SchemaDiff.Create(SnapshotWith([Table("Authors", ["Id"])]),
			SnapshotWith([Table("Authors", ["Id"]), Table("Books", ["Id", "Title"])]));
		Assert.equals("Alter table Books", MigrationNameGenerator.Generate(diff, false));
	}

	function testTwoTablesChanged_NamesMultipleDatabaseChanges() {
		final diff = SchemaDiff.Create(SnapshotWith([Table("Authors", ["Id"]), Table("Books", ["Id"])]),
			SnapshotWith([Table("Authors", ["Id", "Name"]), Table("Books", ["Id", "Title"])]));
		Assert.equals("Multiple database changes", MigrationNameGenerator.Generate(diff, false));
	}

	function testSingleTypeAltered_NamesTheType() {
		final from = SnapshotWith([Table("Invoices", ["Id"])]);
		from.Types.push(Currency("Zar"));
		final to = SnapshotWith([Table("Invoices", ["Id"])]);
		to.Types.push(Currency("Forex"));
		Assert.equals("Alter type Currency", MigrationNameGenerator.Generate(SchemaDiff.Create(from, to), false));
	}

	function testSingleTypeAdded_NamesTheType() {
		final from = SnapshotWith([Table("Invoices", ["Id"])]);
		final to = SnapshotWith([Table("Invoices", ["Id"])]);
		to.Types.push(Currency("Zar"));
		Assert.equals("Add type Currency", MigrationNameGenerator.Generate(SchemaDiff.Create(from, to), false));
	}

	function testSingleTypeDropped_NamesTheType() {
		final from = SnapshotWith([Table("Invoices", ["Id"])]);
		from.Types.push(Currency("Zar"));
		final to = SnapshotWith([Table("Invoices", ["Id"])]);
		Assert.equals("Drop type Currency", MigrationNameGenerator.Generate(SchemaDiff.Create(from, to), false));
	}
}
