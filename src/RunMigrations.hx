import codequery.execution.DatabaseConfiguration;
import codequery.migrations.DatabaseInitializer;
import codequery.migrations.SchemaBuilder;
import codequery.migrations.SchemaSnapshot;
import codequery.runtimes.php.PhpDriver;
/**
	The schema, end to end: read off the entities while compiling, written out as a migration with
	its SQL and its snapshot, applied to a database, used, and undone.

	The PHP target, against an in-memory SQLite database, and into a folder it makes fresh each
	time — so it needs nothing set up and the migration it writes is the one it then runs.
**/
class RunMigrations {
	static function main() {
		final folder = Sys.args().length > 0 ? Sys.args()[0] : "bin/migrations";
		if (sys.FileSystem.exists(folder)) {
			for (name in sys.FileSystem.readDirectory(folder)) {
				for (file in sys.FileSystem.readDirectory('$folder/$name')) {
					sys.FileSystem.deleteFile('$folder/$name/$file');
				}
				sys.FileSystem.deleteDirectory('$folder/$name');
			}
		} else {
			sys.FileSystem.createDirectory(folder);
		}
		final db = new sample.SampleDb();
		final driver = new PhpDriver("sqlite::memory:");
		final schema = DatabaseInitializer.On(SchemaBuilder.Of(db), folder, driver);

		Sys.println('-- changes since the last snapshot: ${schema.PendingChanges().length}');
		final written = schema.AddMigrationIfSchemaChanged("initial");
		Sys.println('-- wrote ${written.Name}');
		Sys.println(written.Up.split("\n")[0]);
		Sys.println(written.Down.split("\n")[0]);

		// Written, so the next diff is against its snapshot and finds nothing.
		Sys.println('-- changes now: ${schema.PendingChanges().length}');
		Sys.println('-- second scaffold: ${schema.AddMigrationIfSchemaChanged("again") == null ? "nothing to write" : "wrote one"}');

		Sys.println('-- pending: ${schema.PendingMigrations().length}');
		Sys.println('-- applied: ${schema.RunPendingMigrations()}');
		Sys.println('-- pending after: ${schema.PendingMigrations().length}');

		// The tables the migration made are the ones the queries want.
		final config = schema.Config;
		final ada = new sample.Guest(1);
		ada.name = "Ada Lovelace";
		ada.email = "ada@example.com";
		Sys.println('-- inserted ${config.Execute(db.Guests.Insert(ada))} into the migrated schema');
		for (row in config.Fetch(db.Guests.From().ToExpression())) {
			Sys.println('   ${row.get("name")} <${row.get("email")}>');
		}

		Sys.println('-- rolled back: ${schema.Rollback()}');
		Sys.println('-- pending again: ${schema.PendingMigrations().length}');
	}
}
