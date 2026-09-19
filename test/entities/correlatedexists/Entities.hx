package entities.correlatedexists;

/** The entities `CorrelatedExistsTests.cs` declares. */
@tableName("projects")
class Project {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

@tableName("watches")
class Watch {
	public var id:Int = 0;
	public var projectId:Int = 0;
	public var userId:Int = 0;

	public function new() {}
}

@tableName("members")
class Member {
	public var id:Int = 0;
	public var projectId:Int = 0;
	public var userId:Int = 0;

	public function new() {}
}
