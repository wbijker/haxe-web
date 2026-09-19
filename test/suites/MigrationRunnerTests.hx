package suites;

import codequery.migrations.*;
import codequery.migrations.MigrationRunner;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import sys.FileSystem;
import sys.io.File;

class RunnerAuthor {
	public var id:Int = 0;
	public var name:String = "";
	public var email:Null<String>;

	public function new() {}
}

class RunnerBook {
	public var id:Int = 0;
	public var title:String = "";

	public function new() {}
}

/** A folder of one test's own, made fresh and taken away after. */
class TempFolder {
	public static function Make(prefix:String):String {
		final folder = 'bin/test-tmp/$prefix-${Std.random(0x7fffffff)}';
		if (!FileSystem.exists("bin")) FileSystem.createDirectory("bin");
		if (!FileSystem.exists("bin/test-tmp")) FileSystem.createDirectory("bin/test-tmp");
		FileSystem.createDirectory(folder);
		return folder;
	}

	public static function Remove(folder:String):Void {
		if (!FileSystem.exists(folder)) {
			return;
		}
		for (name in FileSystem.readDirectory(folder)) {
			final path = '$folder/$name';
			if (FileSystem.isDirectory(path)) {
				Remove(path);
			} else {
				FileSystem.deleteFile(path);
			}
		}
		FileSystem.deleteDirectory(folder);
	}

	public static function Folders(folder:String):Array<String> {
		final names = [for (name in FileSystem.readDirectory(folder)) if (FileSystem.isDirectory('$folder/$name')) name];
		names.sort((a, b) -> a < b ? -1 : (a > b ? 1 : 0));
		return names;
	}
}

/** `MigrationRunnerTests.cs`: what scaffolding a migration writes. Applying one needs a database, which eval has none of. */
class MigrationRunnerTests extends TestCase {
	static inline final Database = "needs a database: eval has none (PHP runtime only)";

	var dir:String;
	final translator = new SqlTranslator();

	override public function setUp() {
		dir = TempFolder.Make("codequery-mig-tests");
	}

	override public function tearDown() {
		TempFolder.Remove(dir);
	}

	static function AuthorsSchema():SchemaSnapshot {
		final s = new SchemaSnapshot();
		s.DefineTable(RunnerAuthor, "authors").Column(a -> a.id).AutoIncrement().Column(a -> a.name).MaxLength(255).NotNull();
		return s;
	}

	static function AuthorsWithEmailSchema():SchemaSnapshot {
		final s = new SchemaSnapshot();
		s.DefineTable(RunnerAuthor, "authors")
			.Column(a -> a.id).AutoIncrement()
			.Column(a -> a.name).MaxLength(255).NotNull()
			.Column(a -> a.email).MaxLength(255).Null();
		return s;
	}

	static function TwoTableSchema():SchemaSnapshot {
		final s = AuthorsSchema();
		s.DefineTable(RunnerBook, "books").Column(b -> b.id).AutoIncrement().Column(b -> b.title).MaxLength(255).NotNull();
		return s;
	}

	function Add(schema:SchemaSnapshot, allowEmpty:Bool = false):AddMigrationResult {
		return MigrationRunner.AddMigration(schema, dir, translator, null, null, allowEmpty);
	}

	static function BaseName(path:String):String {
		return path.split("/").pop();
	}

	function testAddMigration_FirstRun_WritesFolderWithUpDownAndSnapshot() {
		final result = Add(AuthorsSchema());

		Assert.isTrue(result.HasChanges);
		Assert.matches(~/^[0-9]{14}_Initial$/, result.MigrationName);

		Assert.equals(result.MigrationName, BaseName(result.MigrationDirectory));
		Assert.isTrue(FileSystem.exists(result.MigrationDirectory));
		Assert.equals("up.sql", BaseName(result.UpFilePath));
		Assert.equals("down.sql", BaseName(result.DownFilePath));
		Assert.equals("snapshot.yaml", BaseName(result.SnapshotFilePath));

		final up = File.getContent(result.UpFilePath);
		Assert.contains("CREATE TABLE", up);
		Assert.contains("authors", up);

		final down = File.getContent(result.DownFilePath);
		Assert.contains("DROP TABLE", down);
		Assert.contains("authors", down);

		final snapshotYaml = File.getContent(result.SnapshotFilePath);
		Assert.contains("tables:", snapshotYaml);
		Assert.contains("authors", snapshotYaml);

		final globalSnapshot = '$dir/snapshot.yaml';
		Assert.isTrue(FileSystem.exists(globalSnapshot));
		Assert.equals(File.getContent(result.SnapshotFilePath), File.getContent(globalSnapshot));
	}

	function testAddMigration_GlobalSnapshot_TracksTheNewestMigration() {
		final first = Add(AuthorsSchema());
		final globalSnapshot = '$dir/snapshot.yaml';
		Assert.equals(File.getContent(first.SnapshotFilePath), File.getContent(globalSnapshot));

		final second = Add(AuthorsWithEmailSchema());
		Assert.equals(File.getContent(second.SnapshotFilePath), File.getContent(globalSnapshot));
		Assert.contains("email", File.getContent(globalSnapshot));
	}

	function testAddMigration_NoChanges_StillWritesGlobalSnapshot() {
		Add(AuthorsSchema());
		final globalSnapshot = '$dir/snapshot.yaml';
		FileSystem.deleteFile(globalSnapshot);

		final result = Add(AuthorsSchema());
		Assert.isFalse(result.HasChanges);
		Assert.isTrue(FileSystem.exists(globalSnapshot));
	}

	function testAddMigration_UpSql_IncludesAPlainLanguageChangeSummary() {
		final first = Add(AuthorsSchema());
		final up = File.getContent(first.UpFilePath);
		Assert.contains("-- Changes:", up);
		Assert.contains("Create table \"authors\"", up);

		final second = Add(AuthorsWithEmailSchema());
		final up2 = File.getContent(second.UpFilePath);
		Assert.contains("-- Changes:", up2);
		Assert.contains("Add column \"authors\".\"email\"", up2);
		Assert.doesNotContain("Create table", up2);
	}

	function testAddMigration_ReturnsTrueWhenChanges_FalseWhenUpToDate() {
		Assert.isTrue(Add(AuthorsSchema(), true).HasChanges);
		Assert.isFalse(Add(AuthorsSchema(), false).HasChanges);
	}

	function testAddMigration_PrettyPrintsGeneratedDdl() {
		final up = File.getContent(Add(AuthorsSchema()).UpFilePath);
		// Pretty-printed CREATE TABLE: opening paren then each column on its own indented line.
		Assert.contains("(\n    ", up);
		Assert.contains(",\n    ", up);
	}

	function testAddMigration_NoChanges_ReturnsHasChangesFalse() {
		final schema = AuthorsSchema();
		final result = MigrationRunner.AddMigration(schema, dir, translator, null, SchemaSnapshot.FromSchema(schema));
		Assert.isFalse(result.HasChanges);
		Assert.isNull(result.MigrationDirectory);
		Assert.isNull(result.UpFilePath);
		Assert.isNull(result.DownFilePath);
		Assert.isNull(result.SnapshotFilePath);
	}

	function testAddMigration_SecondRun_DiffsAgainstLatestSnapshot() {
		Add(AuthorsSchema(), true);
		final second = Add(AuthorsWithEmailSchema());
		Assert.isTrue(second.HasChanges);
		final up = File.getContent(second.UpFilePath);
		Assert.contains("email", up);
		Assert.doesNotContain("CREATE TABLE", up);
		Assert.contains("email", File.getContent(second.DownFilePath));
	}

	function testLoadLatestSnapshot_ReturnsTheNewestMigrationsSnapshot() {
		Add(AuthorsSchema(), true);
		Add(AuthorsWithEmailSchema());
		final latest = MigrationRunner.LoadLatestSnapshot(dir);
		Assert.notNull(latest);
		Assert.isTrue(Lambda.exists(latest.GetTable("authors").Columns, c -> c.Name == "email"));
	}

	function testRebuildMigrations_RegeneratesUpAndDownFromSnapshots_MostRecentFirst() {
		final first = Add(AuthorsSchema());
		final second = Add(AuthorsWithEmailSchema());

		File.saveContent(second.UpFilePath, "-- broken\n");
		File.saveContent(second.DownFilePath, "-- broken\n");

		final rebuilt = MigrationRunner.RebuildMigrations(dir, translator);

		Assert.equals([second.MigrationName, first.MigrationName], rebuilt);
		Assert.isTrue(FileSystem.exists('${second.MigrationDirectory}/snapshot.yaml'));

		final up = File.getContent(second.UpFilePath);
		Assert.doesNotContain("broken", up);
		Assert.contains("email", up);
		Assert.contains("email", File.getContent(second.DownFilePath));
	}

	function testRebuildMigrations_LastN_LimitsToNewestMigrations() {
		final first = Add(AuthorsSchema());
		final second = Add(AuthorsWithEmailSchema());
		File.saveContent(first.UpFilePath, "-- untouched\n");

		final rebuilt = MigrationRunner.RebuildMigrations(dir, translator, 1);
		Assert.equals([second.MigrationName], rebuilt);
		Assert.contains("untouched", File.getContent(first.UpFilePath));
	}

	function testRebuildMigrations_NoMigrations_ReturnsEmpty() {
		Assert.empty(MigrationRunner.RebuildMigrations(dir, translator));
	}

	function testPendingMigrations_CountsUnappliedThenZeroAfterRun() Assert.skip(Database);
	function testRunPendingMigrations_AppliesPendingAndIsIdempotent() Assert.skip(Database);
	function testRunMigrations_RecordsHistory() Assert.skip(Database);
	function testRunMigrations_RecordsTheIdAndNothingRepeatingIt() Assert.skip(Database);
	function testRunMigrations_AppliesAllStatementsInAMultiTableMigration() Assert.skip(Database);

	function testAddMigration_AllowEmpty_WritesEmptyMigrationWhenUpToDate() {
		Add(AuthorsSchema(), true);
		Assert.isTrue(Add(AuthorsSchema(), true).HasChanges);

		final folders = TempFolder.Folders(dir);
		Assert.equals(2, folders.length);
		Assert.endsWith("_Empty", folders[1]);

		final up = File.getContent('$dir/${folders[1]}/up.sql');
		Assert.doesNotContain("CREATE TABLE", up);
		Assert.doesNotContain("ALTER TABLE", up);
		Assert.doesNotContain("DROP TABLE", up);
	}

	function testAddMigration_AllowEmptyFalse_WritesNothingWhenUpToDate() {
		Add(AuthorsSchema(), true);
		Assert.isFalse(Add(AuthorsSchema(), false).HasChanges);
		Assert.single(TempFolder.Folders(dir));
	}

	function testDropAndRecreate_DropsEverythingAndReappliesMigrations() Assert.skip(Database);
	function testRunMigrations_ThrowsWhenAppliedMigrationFileWasEdited() Assert.skip(Database);

	function testAddMigrationIfSchemaChanged_FirstRun_WritesAnOrdinaryMigration() {
		final result = MigrationRunner.AddMigrationIfSchemaChanged(AuthorsSchema(), dir, translator);
		Assert.isTrue(result.HasChanges);
		Assert.matches(~/^[0-9]{14}_Initial$/, result.MigrationName);
		Assert.single(TempFolder.Folders(dir));
		Assert.contains("authors", File.getContent(result.UpFilePath));
	}

	function testAddMigrationIfSchemaChanged_WhenCalledAgain_WritesAnotherMigrationWithOnlyTheDelta() {
		final first = MigrationRunner.AddMigrationIfSchemaChanged(AuthorsSchema(), dir, translator);
		final second = MigrationRunner.AddMigrationIfSchemaChanged(TwoTableSchema(), dir, translator);

		Assert.notEqual(first.MigrationName, second.MigrationName);
		Assert.equals(2, TempFolder.Folders(dir).length);

		final up = File.getContent(second.UpFilePath);
		Assert.contains("books", up);
		Assert.doesNotContain("authors", up);
	}

	function testAddMigrationIfSchemaChanged_WhenNothingDrifted_WritesNothing() {
		final first = MigrationRunner.AddMigrationIfSchemaChanged(AuthorsSchema(), dir, translator);
		final upBefore = File.getContent(first.UpFilePath);

		final again = MigrationRunner.AddMigrationIfSchemaChanged(AuthorsSchema(), dir, translator);
		Assert.isFalse(again.HasChanges);
		Assert.single(TempFolder.Folders(dir));
		Assert.equals(upBefore, File.getContent(first.UpFilePath));
	}

	function testRunPendingMigrations_AppliesEachMigrationAddedByAddMigrationIfSchemaChanged() Assert.skip(Database);

	function testAddMigrationIfSchemaChanged_WhenScaffoldingFails_LeavesNoEmptyFolderBehind() {
		Assert.skip("Profiler/Logger/Interceptor: not ported (ISqlInterceptor.OnSchemaChange)");
	}
}
