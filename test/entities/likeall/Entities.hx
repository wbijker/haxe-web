package entities.likeall;

/** The entities `LikeAllTests.cs` declares. */
class Author {
	public var id:Int = 0;
	public var name:String = "";
	public var bio:Null<String>;
	public var age:Int = 0;

	public function new() {}
}

@tableName("enrollments")
class Enrollment {
	@primaryKey public var studentId:Int = 0;
	@primaryKey public var courseId:Int = 0;
	public var grade:String = "";

	public function new() {}
}
