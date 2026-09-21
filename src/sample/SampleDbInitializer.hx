package sample;

import codequery.ConsoleLogger;
import codequery.execution.DatabaseConfiguration;
import codequery.migrations.DatabaseInitializer;
import codequery.migrations.SchemaBuilder;
import codequery.mysql.MySqlConfiguration;

using codequery.DbSchemaExtensions;

/**
	Builds the sample database from `SampleDb` and owns the configuration it runs against —
	`CodeQuery.Sample.SampleDbInitializer`. Definition (the schema's members) and configuration
	(the connection and the migrations folder) are kept separate.

	The C# original targets PostgreSQL; this one a MySQL server, `docker`/`docker` at
	`127.0.0.1:3306`, database `codequery_sample` — the same shape of local setup. The driver is
	made the same on every target, and only the PHP target can open its connection: PDO is PHP's
	standard database layer, and there is no MySQL client anywhere else this compiles to. So on PHP
	the schema runs, and elsewhere it renders — which is what `Configuration.Executor` being null
	says.
**/
class SampleDbInitializer {
	/** Where the sample's migrations are scaffolded to and applied from. */
	public static inline final MigrationFolder = "Migrations";

	// 127.0.0.1 rather than localhost: to PDO, localhost means the MySQL socket file, which a
	// server in a container does not listen on; the address means the TCP port that it does.
	public static final ConnectionString = "Server=127.0.0.1;Port=3306;Database=codequery_sample;Uid=docker;Pwd=docker";

	/** The sample database, configured once for every app that uses it. */
	public static function Create():SampleDb {
		return DatabaseInitializer.Build(SampleDb, Configure());
	}

	/**
		The configuration on its own: the MySQL driver, connected where the target can connect, and
		a console logger saying every statement as it is sent. Where the target cannot connect —
		nothing but PHP has a MySQL client — the statements go to an executor that runs nothing, so
		the logger still says them.
	**/
	public static function Configure():DatabaseConfiguration {
		#if php
		final config = MySqlConfiguration.Create(ConnectionString);
		#else
		final config = new DatabaseConfiguration(MySqlConfiguration.Create().Driver, new codequery.execution.DryRunExecutor());
		#end
		return config.WithMigrations(MigrationFolder).WithLogger(new ConsoleLogger());
	}

	/**
		Scaffolds a migration if the code schema has drifted from the latest snapshot, then applies
		whatever is outstanding — the C# `db.AddMigrationIfSchemaChanged(run: true)`. Where nothing
		can run, nothing is applied either: a dry run would only re-apply every migration each time.
	**/
	public static function Migrate(db:SampleDb):Array<String> {
		final config = db.Config();
		if (Std.isOfType(config.Executor, codequery.execution.DryRunExecutor)) {
			return [];
		}
		final schema = new DatabaseInitializer(SchemaBuilder.Of(db), config.MigrationFolder, config.Driver, config);
		final written = schema.AddMigrationIfSchemaChanged("sample");
		if (written != null) {
			Sys.println('-- wrote migration ${written.Name}');
		}
		return schema.RunPendingMigrations();
	}
}
