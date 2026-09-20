package codequery;

/** A 16-bit integer — C#'s `short` — so a column declared as one is a `SMALLINT`. */
abstract SmallInt(Int) from Int to Int {
	public inline function new(value:Int) {
		this = value;
	}

	@:op(A > B) static function gt(a:SmallInt, b:SmallInt):Bool return (a : Int) > (b : Int);
	@:op(A >= B) static function gte(a:SmallInt, b:SmallInt):Bool return (a : Int) >= (b : Int);
	@:op(A < B) static function lt(a:SmallInt, b:SmallInt):Bool return (a : Int) < (b : Int);
	@:op(A <= B) static function lte(a:SmallInt, b:SmallInt):Bool return (a : Int) <= (b : Int);
	@:op(A == B) static function eq(a:SmallInt, b:SmallInt):Bool return (a : Int) == (b : Int);
}
