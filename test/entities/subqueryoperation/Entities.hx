package entities.subqueryoperation;

/** The entities `SubqueryOperationTests.cs` declares. */
@tableName("customers")
class Customer {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

@tableName("orders")
class Order {
	public var id:Int = 0;
	public var customerId:Int = 0;
	public var total:Float = 0;
	public var ref:String = "";

	public function new() {}
}
