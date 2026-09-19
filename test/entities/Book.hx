package entities;

class Book {
	public var id:Int = 0;
	public var title:String = "";
	public var authorId:Int = 0;
	public var publishedYear:Int = 0;
	public var publishedDate:codequery.SqlDate;

	public function new() {}
}
