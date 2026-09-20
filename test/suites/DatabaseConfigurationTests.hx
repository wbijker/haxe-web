package suites;

import codequery.execution.DatabaseConfiguration;
import codequery.migrations.MigrationModes;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `DatabaseConfigurationTests.cs`. */
class DatabaseConfigurationTests extends TestCase {
	/** The folder is named, not located; apply mode settles it against where the program runs. */
	function testWithMigrations_KeepsTheFolderName_AndApplyModeRootsIt() {
		final config = new DatabaseConfiguration(new SqlTranslator()).WithMigrations("Migrations");

		Assert.equals("Migrations", config.MigrationFolder);
		Assert.isTrue(haxe.io.Path.isAbsolute(MigrationModes.ApplyPath(config)));
		Assert.endsWith("Migrations", MigrationModes.ApplyPath(config));
	}

	function testWithMigrations_AbsolutePath_IsUsedAsIs() {
		final absolute = haxe.io.Path.normalize(haxe.io.Path.join([Sys.getCwd(), "bin", "codequery-migrations"]));
		final config = new DatabaseConfiguration(new SqlTranslator()).WithMigrations(absolute);

		Assert.equals(absolute, MigrationModes.ApplyPath(config));
	}
}
