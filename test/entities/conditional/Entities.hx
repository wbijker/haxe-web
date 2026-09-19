package entities.conditional;

import codequery.SqlDate;

/** The entities `ConditionalTests.cs` declares. */
enum abstract Status(Int) to Int {
	var Pending = 0;
	var Confirmed = 1;
}

@tableName("booking")
class Booking {
	public var id:Int = 0;
	public var status:Status = Pending;
	public var checkIn:SqlDate;

	public function new() {}
}
