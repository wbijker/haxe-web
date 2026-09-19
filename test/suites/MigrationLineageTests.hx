package suites;

import codequery.migrations.*;
import codequery.migrations.DatabaseColumnType;
import codequery.migrations.MigrationLineage;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import suites.MigrationRunnerTests.TempFolder;
import sys.FileSystem;
import sys.io.File;

class LineageAuthor {
	public var id:Int = 0;
	public var name:String = "";
	public var email:Null<String>;

	public function new() {}
}

class LineageLog {
	public var id:Int = 0;

	public function new() {}
}

/**
	`MigrationLineageTests.cs`: each migration records the schema it was authored against, so a
	migration created in parallel on another branch is detected, and reconcile repairs the head.
**/
class MigrationLineageTests extends TestCase {
	var dir:String;
	final translator = new SqlTranslator();

	override public function setUp() {
		dir = TempFolder.Make("codequery-lineage");
	}

	override public function tearDown() {
		TempFolder.Remove(dir);
	}

	static function AuthorsSchema():SchemaSnapshot {
		final s = new SchemaSnapshot();
		s.DefineTable(LineageAuthor, "authors").Column(a -> a.id).AutoIncrement().Column(a -> a.name).MaxLength(255).NotNull();
		return s;
	}

	static function AuthorsWithEmailSchema():SchemaSnapshot {
		final s = new SchemaSnapshot();
		s.DefineTable(LineageAuthor, "authors")
			.Column(a -> a.id).AutoIncrement()
			.Column(a -> a.name).MaxLength(255).NotNull()
			.Column(a -> a.email).MaxLength(255).Null();
		return s;
	}

	static function MergedSchema():SchemaSnapshot {
		final s = AuthorsWithEmailSchema();
		s.DefineTable(LineageLog, "logs").Column(l -> l.id).AutoIncrement();
		return s;
	}

	/** Writes a migration folder by hand, simulating one authored in parallel on an earlier base. */
	function WriteParallelMigration(id:String, snapshot:SchemaSnapshot, baseHash:String):Void {
		final folder = '$dir/$id';
		FileSystem.createDirectory(folder);
		File.saveContent('$folder/up.sql', "-- parallel\n");
		File.saveContent('$folder/down.sql', "-- parallel\n");
		final document = SchemaSnapshotDocument.FromModel(SchemaCanonicalizer.Canonical(snapshot));
		document.BaseHash = baseHash;
		File.saveContent('$folder/snapshot.yaml', SnapshotSerializer.Serialize(document));
	}

	/** M1 (authors), then a sibling created against M1's schema but landing after M2 (authors+email). */
	function BuildForkedHistory():{siblingId:String, afterM1:SchemaSnapshot} {
		MigrationRunner.AddMigration(AuthorsSchema(), dir, translator);
		final afterM1 = MigrationRunner.LoadLatestSnapshot(dir);
		MigrationRunner.AddMigration(AuthorsWithEmailSchema(), dir, translator);

		final sibling = new SchemaSnapshot();
		sibling.AddTable("logs").AddColumn("Id", DatabaseColumnType.Int, false);
		final siblingId = "99999999999999_ParallelLogs";
		WriteParallelMigration(siblingId, sibling, SchemaCanonicalizer.Fingerprint(afterM1));
		return {siblingId: siblingId, afterM1: afterM1};
	}

	function testAddMigration_RecordsTheBaseItWasAuthoredAgainst() {
		final first = MigrationRunner.AddMigration(AuthorsSchema(), dir, translator);
		final second = MigrationRunner.AddMigration(AuthorsWithEmailSchema(), dir, translator);
		Assert.contains("baseHash:", File.getContent(first.SnapshotFilePath));
		Assert.contains("baseHash:", File.getContent(second.SnapshotFilePath));
		Assert.empty(MigrationLineage.Detect(dir));
	}

	function testDetect_FlagsAParallelMigration() {
		final forked = BuildForkedHistory();
		final stale = MigrationLineage.Detect(dir);
		Assert.equals(forked.siblingId, Assert.single(stale).Id);
	}

	function testAddMigration_OnForkedHistory_Throws() {
		BuildForkedHistory();
		final thrown = Assert.throws(() -> MigrationRunner.AddMigration(AuthorsWithEmailSchema(), dir, translator));
		Assert.isType(thrown, StaleMigrationException);
	}

	function testRunMigrations_AlwaysDetectsForksInTheUnappliedSet() {
		BuildForkedHistory();
		// The fork is caught before any SQL would be applied — here by the check the runner makes first.
		final thrown = Assert.throws(() -> MigrationLineage.ThrowIfStale(dir, MigrationRunner.MigrationIds(dir)));
		Assert.isType(thrown, StaleMigrationException);
	}

	function testReconcile_RepairsAForkedHistory() {
		final forked = BuildForkedHistory();
		Assert.isTrue(MigrationLineage.Detect(dir).length > 0);

		// The merged code contains both branches' changes (email + logs).
		final reconciled = MigrationRunner.ReconcileMigrations(MergedSchema(), dir, translator);

		Assert.equals(forked.siblingId, Assert.single(reconciled));
		Assert.empty(MigrationLineage.Detect(dir));

		// The head snapshot now equals the merged schema. Applying it cleanly needs a database.
		final head = MigrationRunner.LoadLatestSnapshot(dir);
		Assert.notNull(head.GetTable("logs"));
		Assert.isTrue(Lambda.exists(head.GetTable("authors").Columns, c -> c.Name == "email"));
	}

	function testReconcile_OnLinearHistory_ReturnsEmpty() {
		MigrationRunner.AddMigration(AuthorsSchema(), dir, translator);
		MigrationRunner.AddMigration(AuthorsWithEmailSchema(), dir, translator);
		Assert.empty(MigrationRunner.ReconcileMigrations(AuthorsWithEmailSchema(), dir, translator));
	}
}
