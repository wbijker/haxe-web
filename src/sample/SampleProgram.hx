package sample;

import codequery.sqldrivers.SqlDriver;
import codequery.sqlexpressions.SelectExpression;

/**
	`CodeQuery.Sample.Program`, as far as this port reaches.

	The C# original runs its queries against a database and prints the rows. Nothing here can run —
	no driver can execute yet — so each query is rendered instead, which is the half that exists.
	Everything it does beyond selecting is listed at the foot of this file.
**/
class SampleProgram {
	static final db = new SampleDb();
	static final driver = new SqlDriver();

	static function main() {
		// A projection, including a member flattened into the row it sits on.
		show(db.Bookings.From()
			.Select(b -> {id: b.id, nights: b.totalCents, zar: b.price.zar})
			.ToExpression());

		// The stays query: bookings with their unit and guest, named by position.
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

		// An enum abstract's member is its value by the time SQL sees it.
		show(db.Bookings.From()
			.Where(b -> b.status == BookingStatus.Cancelled && b.refundCents > 0)
			.OrderByDesc(b -> b.refundCents)
			.Limit(10)
			.ToExpression());

		// What C# asks for with Count(). Running it needs a connection; the statement does not.
		show(db.Bookings.From().Where(b -> b.unitId == 10).CountExpression());

		// The takings per unit.
		show(db.Bookings.From()
			.Where(b -> b.status == BookingStatus.Confirmed)
			.GroupBy(b -> b.unitId)
			.SelectAggregation(a -> {
				stays: a.count(),
				takings: a.sum(b -> b.totalCents),
				longest: a.max(b -> b.totalCents)
			})
			.ToExpression());

		// Units that have ever been booked, and units that never have.
		show(db.Units.From()
			.WhereExists(db.Bookings, (u, b) -> b.unitId == u.id && b.status == BookingStatus.Confirmed)
			.ToExpression());

		show(db.Units.From()
			.WhereNotExists(db.Bookings, (u, b) -> b.unitId == u.id)
			.ToExpression());

		// A running total per unit, over a window.
		show(db.Bookings.From()
			.Window(w -> w.PartitionBy(b -> b.unitId).OrderBy(b -> b.checkIn))
			.SelectAggregation((a, w) -> {running: a.sum(b -> b.totalCents).over(w)})
			.ToExpression());

		// The parts catalogue.
		show(db.Parts.From()
			.Where(p -> p.description != null)
			.OrderBy(p -> p.engPartNo)
			.ToExpression());

		mutations();
	}

	/** What Program.cs writes, as the statements that would do it. */
	static function mutations() {
		// Update, with a value and with an expression over the row.
		write(db.Bookings.Update()
			.Set(b -> b.status, BookingStatus.Cancelled)
			.Set(b -> b.refundCents, b -> b.totalCents / 2)
			.Where(b -> b.id == 7)
			.ToExpression());

		write(db.Bookings.Delete()
			.Where(b -> b.status == BookingStatus.Cancelled && b.refundCents == 0)
			.ToExpression());

		// RETURNING what was touched.
		write(db.Units.Update()
			.Set(u -> u.cleaningFeeCents, 4500)
			.Where(u -> u.sleeps > 4)
			.Returning(u -> {id: u.id, fee: u.cleaningFeeCents})
			.ToExpression());

		// An insert reads the entity's members while compiling, the flattened one included.
		final ada = new Guest(0);
		ada.name = "Ada Lovelace";
		write(db.Guests.Insert(ada));

		final seaside = new Unit(0);
		seaside.name = "Seaside cottage";
		seaside.sleeps = 4;
		seaside.baseRateCents = 12000;
		seaside.cleaningFeeCents = 3500;
		write(db.Units.Insert(seaside));
	}

	static function write(statement:codequery.sqlexpressions.ISqlStatement) {
		Sys.println(driver.ToSql(statement));
	}

	static function show(statement:SelectExpression) {
		Sys.println(driver.ToSql(statement));
	}
}
