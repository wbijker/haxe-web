package sample;

/** A price in two currencies. Flattened into the row it sits on, as `Price_Type` and the rest. */
class CurrentObject {
	public var type:Int = 0;
	public var forex:Float = 0;
	public var zar:Float = 0;

	public function new() {}
}
