package sample;

import codequery.DbTable;
import codequery.DbView;
import codequery.IDbSchema;

/**
	The sample schema, ported from `CodeQuery.Sample.SampleDb`: a small vacation-booking schema —
	guests, the units they rent, and the bookings between them — plus the parts catalogue.

	The C# original also declares a view, two functions and two stored procedures. Those need
	`DbView`, `DbFunction` and `DbStoredProc`, none of which this port has, so the tables are what
	is here. A live instance is built by `SampleDbInitializer`.
**/
class SampleDb implements IDbSchema {
	public final Guests:DbTable<Guest> = DbTable.of();
	public final Units:DbTable<Unit> = DbTable.of();
	public final Bookings:DbTable<Booking> = DbTable.of();
	public final Parts:DbTable<Part> = DbTable.of();

	/**
		The empty windows between a unit's stays. The C# original pairs each check-out with the next
		check-in using LEAD(); this is the part of it that can be said so far.
	**/
	public final AvailabilityGaps:DbView<AvailabilityGap> = DbView.of(codequery.Query.select(Booking)
		.Where(b -> b.status == BookingStatus.Confirmed)
		.Select(b -> {unitId: b.unitId, bookingId: b.id, gapStart: b.checkOut}));

	public function new() {}
}
