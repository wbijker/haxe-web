package model;

/** A place stock is delivered from or to. */
@tableName("store")
class Store {
	public var id:Int;
	public var code:String = "";
	public var name:String = "";

	public function new(id:Int) {
		this.id = id;
	}
}
