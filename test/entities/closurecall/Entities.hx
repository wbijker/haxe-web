package entities.closurecall;

import codequery.SqlDate;

/** The entity `ClosureCallTests.cs` declares. */
@tableName("parts")
class Part {
	public var id:Int = 0;
	public var name:String = "";
	public var created:SqlDate;

	public function new() {}
}
