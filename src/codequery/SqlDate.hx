package codequery;

/**
	A date a query can compare.

	C#'s `DateTime` carries its comparisons, so `b.CheckIn < b.CheckOut` is ordinary C#. Haxe's
	`Date` does not, and a predicate has to type before it can be converted — so without these a
	date could only ever be tested for equality. Converting to and from `Date` is free.
**/
abstract SqlDate(Date) from Date to Date {
	public inline function new(date:Date) {
		this = date;
	}

	@:op(A < B) static function lt(a:SqlDate, b:SqlDate):Bool {
		return (a : Date).getTime() < (b : Date).getTime();
	}

	@:op(A <= B) static function lte(a:SqlDate, b:SqlDate):Bool {
		return (a : Date).getTime() <= (b : Date).getTime();
	}

	@:op(A > B) static function gt(a:SqlDate, b:SqlDate):Bool {
		return (a : Date).getTime() > (b : Date).getTime();
	}

	@:op(A >= B) static function gte(a:SqlDate, b:SqlDate):Bool {
		return (a : Date).getTime() >= (b : Date).getTime();
	}
}
