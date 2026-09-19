package entities.constructedvalue;

/** The entity `ConstructedValueTests.cs` declares — without its Guid and TimeSpan, which Haxe has no type for. */
@tableName("job")
class Job {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}
