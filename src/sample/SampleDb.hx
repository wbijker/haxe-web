package sample;

import codequery.DbTable;

/**
	The sample schema, ported from `CodeQuery.Sample.SampleDb`: a small vacation-booking schema —
	guests, the units they rent, and the bookings between them — plus the parts catalogue.

	The C# original also declares a view, two functions and two stored procedures. Those need
	`DbView`, `DbFunction` and `DbStoredProc`, none of which this port has, so the tables are what
	is here.
**/
class SampleDb {
	public final Guests:DbTable<Guest> = DbTable.of();
	public final Units:DbTable<Unit> = DbTable.of();
	public final Bookings:DbTable<Booking> = DbTable.of();
	public final Parts:DbTable<Part> = DbTable.of();

	public function new() {}
}
