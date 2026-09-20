package codequery;

import codequery.execution.DatabaseConfiguration;
import codequery.migrations.SchemaBindings;
import codequery.migrations.SchemaSnapshot;

/**
	What a built declared schema can be asked — reached with `using codequery.DbSchemaExtensions;`,
	as C#'s extension methods of the same names are.
**/
class DbSchemaExtensions {
	/** The snapshot the schema was built into. Throws for a schema nothing has built. */
	public static function Snapshot(schema:IDbSchema):SchemaSnapshot {
		final snapshot = SchemaBindings.SnapshotOf(schema);
		if (snapshot == null) {
			final name = Type.getClassName(Type.getClass(schema)).split(".").pop();
			throw 'The schema $name has not been built. Build it with DatabaseInitializer.Build($name, configuration) before asking for its snapshot.';
		}
		return snapshot;
	}

	/** The configuration the schema was built against. */
	public static function Config(schema:IDbSchema):Null<DatabaseConfiguration> {
		Snapshot(schema);
		return SchemaBindings.ConfigOf(schema);
	}
}
