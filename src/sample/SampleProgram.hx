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
	}

	static function show(statement:SelectExpression) {
		Sys.println(driver.ToSql(statement));
	}
}
