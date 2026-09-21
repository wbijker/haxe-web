import codequery.sqlexpressions.ISqlStatement;
import sample.SampleDb;
import sample.SampleDbInitializer;

using codequery.DbSchemaExtensions;

/**
	`CodeQuery.Sample.Program`.

	The C# original runs against PostgreSQL. This one is built by `SampleDbInitializer` over a
	MySQL driver, which the PHP target connects through PDO; every other target has no MySQL
	client, so there the same statements are rendered instead of run.
**/
class Main {
	static final db:SampleDb = SampleDbInitializer.Create();

	static function main() {
		final config = db.Config();
		if (config.Executor != null) {
			// Scaffold a migration if the schema has drifted, then apply whatever is outstanding.
			final applied = SampleDbInitializer.Migrate(db, config);
			Sys.println('-- applied ${applied.length} migration(s)');
		}

		final repriced = db.Bookings.Update()
			.Where(f -> f.price.zar > 100)
			.Set(g -> g.price.zar, g -> g.price.zar * 1.15);

		show(repriced.ToExpression());
		if (config.Executor != null) {
			Sys.println('-- repriced ${repriced.Execute()} booking(s)');
		}
	}

	static function section(title:String) {
		Sys.println('\n-- $title');
	}

	/** The statement as the sample's driver renders it. */
	static function show(statement:ISqlStatement) {
		Sys.println(db.Config().Render(statement).Sql);
	}
}
