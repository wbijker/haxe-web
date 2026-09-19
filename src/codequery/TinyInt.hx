package codequery;

/** An 8-bit integer — C#'s `byte` — so a column declared as one is a `TINYINT`. */
abstract TinyInt(Int) from Int to Int {
	public inline function new(value:Int) {
		this = value;
	}

	@:op(A > B) static function gt(a:TinyInt, b:TinyInt):Bool return (a : Int) > (b : Int);
	@:op(A >= B) static function gte(a:TinyInt, b:TinyInt):Bool return (a : Int) >= (b : Int);
	@:op(A < B) static function lt(a:TinyInt, b:TinyInt):Bool return (a : Int) < (b : Int);
	@:op(A <= B) static function lte(a:TinyInt, b:TinyInt):Bool return (a : Int) <= (b : Int);
	@:op(A == B) static function eq(a:TinyInt, b:TinyInt):Bool return (a : Int) == (b : Int);
}
