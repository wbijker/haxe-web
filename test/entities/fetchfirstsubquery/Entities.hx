package entities.fetchfirstsubquery;

/** The entities `FetchFirstSubqueryTests.cs` declares. */
@tableName("booking")
class Booking {
	public var id:Int = 0;
	public var unitId:Int = 0;

	public function new() {}
}

@tableName("unit")
class Unit {
	public var id:Int = 0;
	public var sleeps:Int = 0;
	public var baseRateCents:Int = 0;

	public function new() {}
}
