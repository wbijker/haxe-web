package sample;

/** A price in two currencies. Flattened into the row it sits on, as `Price_Type` and the rest. */
class CurrentObject {
	public var type:Int;
	public var forex:Float;
	public var zar:Float;

	public function new() {}
}
