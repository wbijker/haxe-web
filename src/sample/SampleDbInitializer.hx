package sample;

import codequery.execution.DatabaseConfiguration;
import codequery.migrations.DatabaseInitializer;
import codequery.migrations.SchemaBuilder;
import codequery.mysql.MySqlConfiguration;

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

	/** The configuration on its own: the MySQL driver, connected where the target can connect. */
	public static function Configure():DatabaseConfiguration {
		#if php
		return MySqlConfiguration.Create(ConnectionString).WithMigrations(MigrationFolder);
		#else
		return MySqlConfiguration.Create().WithMigrations(MigrationFolder);
		#end
	}

	/**
		Scaffolds a migration if the code schema has drifted from the latest snapshot, then applies
		whatever is outstanding — the C# `db.AddMigrationIfSchemaChanged(run: true)`.
	**/
	public static function Migrate(db:SampleDb, config:DatabaseConfiguration):Array<String> {
		final schema = new DatabaseInitializer(SchemaBuilder.Of(db), config.MigrationFolder, config.Driver, config);
		final written = schema.AddMigrationIfSchemaChanged("sample");
		if (written != null) {
			Sys.println('-- wrote migration ${written.Name}');
		}
		return schema.RunPendingMigrations();
	}
}
