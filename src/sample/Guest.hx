package sample;

@tableName("guest")
class Guest {
	public var id:Int;

	@columnNullable(false)
	@columnMaxLength(120)
	public var name:String = "";

	public var email:Null<String>;

	public function new(id:Int) {
		this.id = id;
	}
}
