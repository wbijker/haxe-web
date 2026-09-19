package entities.scalarsubquery;

/** The entities `ScalarSubqueryTests.cs` declares. */
@tableName("Customer")
class Customer {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

@tableName("Job")
class Job {
	public var id:Int = 0;
	public var customerId:Int = 0;

	public function new() {}
}

@tableName("Line")
class Line {
	public var id:Int = 0;
	public var jobId:Int = 0;

	public function new() {}
}

@tableName("Order")
class Order {
	public var id:Int = 0;
	public var customerId:Int = 0;
	public var total:Float = 0;

	public function new() {}
}
