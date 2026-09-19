package codequery;

/**
	A span of time a query can compare and add — C#'s `TimeSpan`, which becomes SQL's interval.

	The difference of two `SqlDate`s is one of these, and it is compared against one:

	```haxe
	.Where(b -> Date.now() - b.created > SqlInterval.days(3))
	// NOW() - t0.created > INTERVAL '3 days'
	```

	Held as milliseconds. Nothing here runs inside a query — a lambda is read while compiling and a
	span that reads no row becomes an `IntervalSqlExpression` — but outside one it is an ordinary
	value, which is what lets a span be held in a variable and handed in.
**/
abstract SqlInterval(Float) {
	public inline function new(milliseconds:Float) {
		this = milliseconds;
	}

	/** The span in milliseconds. */
	public var Milliseconds(get, never):Float;

	inline function get_Milliseconds():Float {
		return this;
	}

	public static function days(count:Float):SqlInterval return new SqlInterval(count * 86400000.0);
	public static function hours(count:Float):SqlInterval return new SqlInterval(count * 3600000.0);
	public static function minutes(count:Float):SqlInterval return new SqlInterval(count * 60000.0);
	public static function seconds(count:Float):SqlInterval return new SqlInterval(count * 1000.0);
	public static function milliseconds(count:Float):SqlInterval return new SqlInterval(count);

	/** `new TimeSpan(days, hours, minutes, seconds, milliseconds)`. */
	public static function of(days:Int, hours:Int, minutes:Int, seconds:Int, milliseconds:Int = 0):SqlInterval {
		return new SqlInterval(((days * 24.0 + hours) * 60.0 + minutes) * 60000.0 + seconds * 1000.0 + milliseconds);
	}

	public static function zero():SqlInterval return new SqlInterval(0);

	/** A date a span later — `Date.now() + span`, where the date is not yet a `SqlDate`. */
	@:op(A + B) static function after(date:Date, span:SqlInterval):SqlDate {
		return Date.fromTime(date.getTime() + span.Milliseconds);
	}

	/** A date a span earlier. */
	@:op(A - B) static function before(date:Date, span:SqlInterval):SqlDate {
		return Date.fromTime(date.getTime() - span.Milliseconds);
	}

	@:op(A < B) static function lt(a:SqlInterval, b:SqlInterval):Bool return a.Milliseconds < b.Milliseconds;
	@:op(A <= B) static function lte(a:SqlInterval, b:SqlInterval):Bool return a.Milliseconds <= b.Milliseconds;
	@:op(A > B) static function gt(a:SqlInterval, b:SqlInterval):Bool return a.Milliseconds > b.Milliseconds;
	@:op(A >= B) static function gte(a:SqlInterval, b:SqlInterval):Bool return a.Milliseconds >= b.Milliseconds;
	@:op(A == B) static function eq(a:SqlInterval, b:SqlInterval):Bool return a.Milliseconds == b.Milliseconds;
	@:op(A != B) static function neq(a:SqlInterval, b:SqlInterval):Bool return a.Milliseconds != b.Milliseconds;
}
