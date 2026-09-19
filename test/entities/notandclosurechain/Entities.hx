package entities.notandclosurechain;

/** The entities `NotAndClosureChainTests.cs` declares. */
class Order {
	public var id:Int = 0;
	public var shipped:Bool = false;
	public var customerId:Int = 0;

	public function new() {}
}

class Customer {
	public var id:Int = 0;

	public function new() {}
}
