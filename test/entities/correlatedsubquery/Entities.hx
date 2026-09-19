package entities.correlatedsubquery;

/** The entities `CorrelatedSubqueryTests.cs` declares. */
class Customer {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

class Order {
	public var id:Int = 0;
	public var customerId:Int = 0;
	public var total:Float = 0;

	public function new() {}
}
