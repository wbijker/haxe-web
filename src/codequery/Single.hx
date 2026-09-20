package codequery;

/** A single-precision number — C#'s `float` — so a column declared as one is a `REAL`. Haxe's `Float` is `double`. */
abstract Single(Float) from Float from Int to Float {
	public inline function new(value:Float) {
		this = value;
	}

	@:op(A > B) static function gt(a:Single, b:Single):Bool return (a : Float) > (b : Float);
	@:op(A >= B) static function gte(a:Single, b:Single):Bool return (a : Float) >= (b : Float);
	@:op(A < B) static function lt(a:Single, b:Single):Bool return (a : Float) < (b : Float);
	@:op(A <= B) static function lte(a:Single, b:Single):Bool return (a : Float) <= (b : Float);
}
