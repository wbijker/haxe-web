package codequery;

/** One character — C#'s `char` — so a column declared as one is a `CHAR(1)`. */
abstract Char(String) from String to String {
	public inline function new(text:String) {
		this = text;
	}

	@:op(A == B) static function eq(a:Char, b:Char):Bool return (a : String) == (b : String);
}
