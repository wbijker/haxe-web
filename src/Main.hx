import sample.SampleDb;
import sample.SampleDbInitializer;

/**
	`CodeQuery.Sample.Program`.

	The C# original runs against PostgreSQL. This one is built by `SampleDbInitializer` over a
	MySQL driver, which the PHP target connects through PDO; every other target has no MySQL
	client, so there the same statements go to an executor that runs nothing. Either way the
	configuration's console logger says each statement as it is sent, and what came back.
**/
class Main {
	static final db:SampleDb = SampleDbInitializer.Create();

	static function main() {
		// Scaffold a migration if the schema has drifted, then apply whatever is outstanding.
		SampleDbInitializer.Migrate(db);

		var rows = db.Bookings.From()
		.Where(b -> b.price.zar > 100)
		.Select(b -> {
			price: b.price.zar,
			id: b.id,
			another: b.totalCents
		}).Select(b -> {
			pp: b.price + b.id + b.another
		}).Fetch();

		db.Bookings.Update()
			.Where(f -> f.price.zar > 100)
			.Set(g -> g.price.zar, g -> g.price.zar * 1.15)
			.Execute();
	}
}
