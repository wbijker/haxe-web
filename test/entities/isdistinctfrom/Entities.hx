package entities.isdistinctfrom;

/** The entity `IsDistinctFromTests.cs` declares. */
@tableName("units")
class Unit {
	public var name:Null<String>;
	public var sleeps:Int = 0;
	public var notes:Null<String>;
	public var previousName:Null<String>;
	public var previousSleeps:Int = 0;

	public function new() {}
}
