import codequery.execution.DatabaseConfiguration;
import codequery.runtimes.php.PdoExecutor;
import codequery.runtimes.php.PhpDriver;
import sample.BookingStatus;

/**
	The port, end to end: rendered here, run by PHP, rows back.

	The PHP target only — `PdoExecutor` is where this stops being about rendering — and against an
	in-memory SQLite database, so it needs nothing set up and leaves nothing behind.
**/
class RunPhp {
	static function main() {
		final db = new sample.SampleDb();
		final driver = new PhpDriver("sqlite::memory:");
		final config = DatabaseConfiguration.Of(driver);

		// The schema itself is not something this port builds yet.
		final executor:PdoExecutor = cast driver.Executor();
		executor.Raw("CREATE TABLE guest (id INTEGER PRIMARY KEY, name TEXT, email TEXT)");
		executor.Raw("CREATE TABLE unit (id INTEGER PRIMARY KEY, name TEXT, sleeps INT,
			baseRateCents INT, cleaningFeeCents INT)");
		executor.Raw("CREATE TABLE booking (id INTEGER PRIMARY KEY, unitId INT, guestId INT,
			checkIn TEXT, checkOut TEXT, status INT, totalCents INT, refundCents INT,
			price_type INT, price_forex REAL, price_zar REAL)");

		final ada = new sample.Guest(1);
		ada.name = "Ada Lovelace";
		ada.email = "ada@example.com";
		Sys.println('inserted ${config.Execute(db.Guests.Insert(ada))} guest');

		final grace = new sample.Guest(2);
		grace.name = "Grace Hopper";
		Sys.println('inserted ${config.Execute(db.Guests.Insert(grace))} guest');

		final seaside = new sample.Unit(1);
		seaside.name = "Seaside cottage";
		seaside.sleeps = 4;
		seaside.baseRateCents = 12000;
		seaside.cleaningFeeCents = 3500;
		config.Execute(db.Units.Insert(seaside));

		final stay = new sample.Booking(1);
		stay.unitId = 1;
		stay.guestId = 1;
		stay.status = BookingStatus.Confirmed;
		stay.checkIn = new Date(2026, 2, 9, 0, 0, 0);
		stay.checkOut = new Date(2026, 2, 16, 0, 0, 0);
		stay.totalCents = 84000;
		config.Execute(db.Bookings.Insert(stay));

		Sys.println("");
		for (row in config.Fetch(db.Guests.From().OrderBy(g -> g.name).ToExpression())) {
			Sys.println('guest: ${row.get("name")} <${row.get("email")}>');
		}

		Sys.println("");
		final joined = db.Bookings.From()
			.InnerJoin(db.Units, sample.Booking.withUnit)
			.InnerJoin(db.Guests, (b, u, g) -> g.id == b.guestId)
			.Where((b, u, g) -> b.status == BookingStatus.Confirmed)
			.Select((b, u, g) -> {guest: g.name, unit: u.name, cents: b.totalCents});

		Sys.println(config.Render(joined.ToExpression()).Sql);
		for (row in config.Fetch(joined.ToExpression())) {
			Sys.println('  ${row.get("guest")} at ${row.get("unit")} for ${row.get("cents")}c');
		}

		Sys.println("");
		final updated = config.Execute(db.Guests.Update()
			.Set(g -> g.email, "grace@example.com")
			.Where(g -> g.id == 2)
			.ToExpression());
		Sys.println('updated $updated row');
		for (row in config.Fetch(db.Guests.From().Where(g -> g.id == 2).ToExpression())) {
			Sys.println('  now: ${row.get("name")} <${row.get("email")}>');
		}
	}
}
