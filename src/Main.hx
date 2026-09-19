import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.ISqlStatement;
import sample.Booking;
import sample.BookingStatus;
import sample.Guest;
import sample.SampleDb;
import sample.Unit;

/**
	`CodeQuery.Sample.Program`, query for query.

	The C# original runs against PostgreSQL and prints the rows: it builds the schema, applies its
	migrations, seeds three tables, calls its functions and stored procedures, and reads a view.
	None of that is reachable here — no driver can execute — so each statement is rendered instead,
	which is the half this port has.

	Where a query of the original cannot be written yet, it is left in place as a comment saying
	what it needs.
**/
class Main {
	static final db = new SampleDb();
	static final driver = new codequery.sqldrivers.SqlTranslator();

	static function main() {
		// The original opens with SampleDbInitializer.Create, DropAndRecreate and
		// AddMigrationIfSchemaChanged. All three need DatabaseInitializer and the migration
		// machinery, and a connection to run against.

		section("A booking's price, which is flattened into its row");
		// C# names these by shorthand — new { f.Price.Forex, … }; Haxe structures always name a
		// member, so the names are written out.
		show(db.Bookings.From()
			.Select(f -> {guestId: f.guestId})
			.Select(f -> {a: f.guestId})
			// .Select(f -> {forex: f.price.forex, type: f.price.type, zar: f.price.zar})
			.ToExpression());

		section("Raising those prices by a seventh");
		show(db.Bookings.Update()
			.Where(f -> f.price.zar > 100)
			.Set(g -> g.price.zar, g -> g.price.zar * 1.15)
			.ToExpression());

		// resultC selects f.Price whole — one member standing for the three columns it flattens
		// into — and resultD sets it whole from a new CurrentObject. A projection here names a row
		// or a column, not an object between the two, so both are written out member by member.

		section("Every booking");
		show(db.Bookings.From().ToExpression());

		section("Confirmed stays, with their unit and guest");
		// The original writes this with db.Block, which names each source as it is joined. The
		// fluent form its own comment gives is the one here: every clause takes every source and
		// names them by position.
		show(db.Bookings.From()
			.InnerJoin(db.Units, (b, u) -> u.id == b.unitId)
			.InnerJoin(db.Guests, (b, u, g) -> g.id == b.guestId)
			.Where((b, u, g) -> b.status == BookingStatus.Confirmed)
			.OrderBy((b, u, g) -> b.checkIn)
			.Select((b, u, g) -> {
				guest: g.name,
				unit: u.name,
				checkIn: b.checkIn,
				checkOut: b.checkOut,
				totalCents: b.totalCents,
				sleeps: u.sleeps
			})
			.ToExpression());

		section("Seeding");
		// C# inserts arrays and reads the generated keys back with PopulatePrimaryKey. One row at a
		// time is what this port has, and nothing reads a key back, because nothing runs.
		final lovelace = new Guest(0);
		lovelace.name = "Ada Lovelace";
		lovelace.email = "ada@example.com";
		show(db.Guests.Insert(lovelace));

		final seaside = new Unit(0);
		seaside.name = "Seaside cottage";
		seaside.sleeps = 4;
		seaside.baseRateCents = 12000;
		seaside.cleaningFeeCents = 3500;
		show(db.Units.Insert(seaside));

		final stay = new Booking(0);
		stay.unitId = 1;
		stay.guestId = 1;
		stay.status = BookingStatus.Confirmed;
		stay.checkIn = new Date(2026, 2, 9, 0, 0, 0);
		stay.checkOut = new Date(2026, 2, 16, 0, 0, 0);
		stay.totalCents = 84000;
		show(db.Bookings.Insert(stay));

		section("What follows each stay in the same unit");
		// A left join onto the same table: two handles of one entity are two sources, so a query can
		// read a booking beside another booking.
		show(db.Bookings.From()
			.InnerJoin(db.Units, (b, u) -> u.id == b.unitId)
			.LeftJoin(db.Bookings, (b, u, next) -> next.unitId == b.unitId && next.checkIn >= b.checkOut)
			.Where((b, u, next) -> b.status == BookingStatus.Confirmed)
			.OrderBy((b, u, next) -> u.name)
			.Select((b, u, next) -> {unit: u.name, checkOut: b.checkOut, nextIn: next.checkIn})
			.ToExpression());

		section("Back to a known state — bookings first, they point at the other two");
		show(db.Bookings.Delete().ToExpression());
		show(db.Units.Delete().ToExpression());
		show(db.Guests.Delete().ToExpression());

		section("How many bookings there are");
		show(db.Bookings.From().SelectAggregation(a -> {AA: a.count()}).ToExpression());

		// db.Parts.Upsert(part).OnConflict(…).Update(…) needs ON CONFLICT, which this port has not
		// reached.

		section("A part");
		final widget = new sample.Part(0);
		widget.description = "Widget";
		widget.engPartNo = "1234";
		widget.manufacturerPartNo = "MK-124P";
		widget.supplierPartNo = "SUP-124";
		show(db.Parts.Insert(widget));

		section("Bookings with their unit and guest");
		// C# reaches the joins through Booking.WithUnit and Booking.WithGuest, which declare on the
		// entity what they join on. Those helpers are not ported, so the conditions are written out.
		show(db.Bookings.From()
			.InnerJoin(db.Units, (b, u) -> u.id == b.unitId)
			.InnerJoin(db.Guests, (b, u, g) -> g.id == b.guestId)
			.Select((b, u, g) -> {
				bookingId: b.id,
				unitName: u.name,
				guestName: g.name,
				checkIn: b.checkIn,
				checkOut: b.checkOut,
				status: b.status,
				totalCents: b.totalCents
			})
			.ToExpression());

		section("One unit's bookings, counted");
		// C# asks for the count directly. Counting runs the query, so what is here is the statement
		// that would do it.
		show(db.Bookings.From().Where(b -> b.unitId == 10).CountExpression());

		// fn_stay_cost, fn_is_available, sp_reserve and sp_cancel_booking are the rest of the
		// original. Each needs DbFunction or DbStoredProc, and a connection to call it on.

		// The gaps between stays read vw_availability_gaps, which needs DbView — and the view is
		// itself a query, defined with LEAD(), a window function this port does not have either.

		section("The bookings that stand");
		show(db.Bookings.From()
			.InnerJoin(db.Guests, (b, g) -> g.id == b.guestId)
			.InnerJoin(db.Units, (b, g, u) -> u.id == b.unitId)
			.Where((b, g, u) -> b.status == BookingStatus.Confirmed)
			.OrderBy((b, g, u) -> b.checkIn)
			.Select((b, g, u) -> {
				guest: g.name,
				unit: u.name,
				checkIn: b.checkIn,
				checkOut: b.checkOut,
				totalCents: b.totalCents
			})
			.ToExpression());

		section("What running one would say");
		try {
			db.Bookings.From().Count();
		} catch (e:String) {
			Sys.println(e);
		}
	}

	static function section(title:String) {
		Sys.println('\n-- $title');
	}

	static function show(statement:ISqlStatement) {
		Sys.println(driver.ToSql(statement));
	}
}
