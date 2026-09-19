package codequery;

/**
	What a lambda can say that Haxe has no operator for.

	`a.id > 10` is an expression in both languages, so it needs nothing here. `x IN (…)` and
	`CASE WHEN` are SQL and not Haxe, and this is where they are written instead. Nothing here runs:
	a lambda is read while compiling and becomes an expression tree, so these exist to be recognised
	and to make the lambda type-check.

	`CASE WHEN` is the exception — Haxe's `cond ? a : b` says it, so that is what converts.
**/
extern class Sql {
	/** `x IN (…)`. */
	public static function isIn<T>(value:T, values:Array<T>):Bool;

	/** `x NOT IN (…)`. */
	public static function notIn<T>(value:T, values:Array<T>):Bool;

	/** `x IN (<query>)` — the query selects the one column the value is looked for in. */
	public static function inQuery<T, TQuery>(value:T, query:TQuery):Bool;

	/** `x NOT IN (<query>)`. */
	public static function notInQuery<T, TQuery>(value:T, query:TQuery):Bool;

	/** `x BETWEEN lower AND upper`, inclusive at both ends. */
	public static function between<T>(value:T, lower:T, upper:T):Bool;

	/** `x NOT BETWEEN lower AND upper`. */
	public static function notBetween<T>(value:T, lower:T, upper:T):Bool;

	/** `x LIKE pattern` — `%` for any run of characters, `_` for one. */
	public static function like(value:String, pattern:String):Bool;

	/** `x NOT LIKE pattern`. */
	public static function notLike(value:String, pattern:String):Bool;

	/** `x ILIKE pattern` — `LIKE`, ignoring case. */
	public static function ilike(value:String, pattern:String):Bool;

	/** `x NOT ILIKE pattern`. */
	public static function notIlike(value:String, pattern:String):Bool;

	/**
		`a IS DISTINCT FROM b` — two nulls are the same and one null is a difference, where `==`
		would answer unknown to both.
	**/
	public static function isDistinctFrom<T>(left:T, right:T):Bool;

	/** `a IS NOT DISTINCT FROM b`. */
	public static function isNotDistinctFrom<T>(left:T, right:T):Bool;

	/** `COALESCE(a, b, …)` — the first that is not null. */
	public static function coalesce<T>(first:T, rest:haxe.extern.Rest<T>):T;

	/** `NULLIF(a, b)` — null where the two are equal, otherwise `a`. */
	public static function nullIf<T>(value:T, whenEqualTo:T):Null<T>;

	/** `UPPER(x)`. */
	public static function upper(value:String):String;

	/** `LOWER(x)`. */
	public static function lower(value:String):String;

	/** `LENGTH(x)`. */
	public static function length(value:String):Int;

	/** `TRIM(x)`. */
	public static function trim(value:String):String;

	/** `SUBSTRING(x FROM start FOR count)`, counting from one as SQL does. */
	public static function substring(value:String, start:Int, ?count:Int):String;

	/** `a || b || …` — the strings joined, which is not what `+` means in SQL. */
	public static function concat(first:String, rest:haxe.extern.Rest<String>):String;

	/** `CAST(x AS <type>)`. */
	public static function castTo<TFrom, TTo>(value:TFrom, type:codequery.sqlexpressions.SqlType):TTo;

	/**
		SQL written out, for what nothing else here can say.

		Sent as it stands and checked by nothing, so a value belongs in `param` beside it rather
		than written into the text.
	**/
	public static function raw<T>(sql:String):T;

	/**
		A value sent beside the statement rather than written into it.

		Everything else a lambda names becomes a literal in the SQL. This is how a value does not.
	**/
	public static function param<T>(value:T):T;

	/** A subquery standing where a value does — one row of one column. */
	public static function scalar<T, TQuery>(query:TQuery):T;

	/** A subquery that may name the rows of the statement it sits in. */
	public static function correlated<T, TQuery>(query:TQuery):T;

	/** `x <op> ANY (<query>)` — true where it holds for one row of the query. */
	public static function any<T, TQuery>(query:TQuery):T;

	/** `x <op> ALL (<query>)` — true where it holds for every row. */
	public static function all<T, TQuery>(query:TQuery):T;

	/** `EXTRACT(<part> FROM x)` — `year`, `month`, `day`, `hour`, `dow` and the rest. */
	public static function datePart(part:String, value:Date):Int;

	/** `x + INTERVAL 'n unit'` — `days`, `months`, `years` and the rest. */
	public static function dateAdd(value:Date, count:Int, unit:String):Date;

	/** `x - INTERVAL 'n unit'`. */
	public static function dateSubtract(value:Date, count:Int, unit:String):Date;

	/** `percentile_cont(fraction) WITHIN GROUP (ORDER BY x)` — the interpolated percentile. */
	public static function percentileCont(fraction:Float, value:Float):Float;

	/** `percentile_disc(fraction) WITHIN GROUP (ORDER BY x)` — the nearest actual value. */
	public static function percentileDisc(fraction:Float, value:Float):Float;

	/** `percentile_cont(0.5) WITHIN GROUP (ORDER BY x)`. */
	public static function median(value:Float):Float;

	/** `mode() WITHIN GROUP (ORDER BY x)` — the most frequent value. */
	public static function mode<T>(value:T):T;

	/** `ABS(x)`. */
	public static function abs<T:Float>(value:T):T;

	/** `ROUND(x)`, or to `places` decimals. */
	public static function round(value:Float, ?places:Int):Float;

	/** `CEIL(x)`. */
	public static function ceil(value:Float):Float;

	/** `FLOOR(x)`. */
	public static function floor(value:Float):Float;

	/** `SIGN(x)` — -1, 0 or 1. */
	public static function sign(value:Float):Int;

	/** `POWER(x, y)`. */
	public static function power(value:Float, exponent:Float):Float;

	/** `SQRT(x)`. */
	public static function sqrt(value:Float):Float;

	/** `EXP(x)`. */
	public static function exp(value:Float):Float;

	/** `LN(x)` — the natural logarithm. */
	public static function ln(value:Float):Float;

	/** `LOG(x)` — the base-10 logarithm. */
	public static function log(value:Float):Float;

	/** `GREATEST(a, b, …)`. */
	public static function greatest<T>(first:T, rest:haxe.extern.Rest<T>):T;

	/** `LEAST(a, b, …)`. */
	public static function least<T>(first:T, rest:haxe.extern.Rest<T>):T;

	/** `LEFT(s, n)` — the first `n` characters. */
	public static function left(value:String, length:Int):String;

	/** `RIGHT(s, n)` — the last `n` characters. */
	public static function right(value:String, length:Int):String;

	/** `RANDOM()`. */
	public static function random():Float;

	/** `NOW()` — the database's clock. `Date.now()` says the same inside a lambda. */
	public static function now():Date;

	/** `NOW() AT TIME ZONE 'UTC'`. */
	public static function utcNow():Date;

	/** `CURRENT_DATE`. */
	public static function today():Date;

	/** Whether `year` is a leap year — named as C#'s `DateTime.IsLeapYear`; no dialect spells it yet. */
	public static function isLeapYear(year:Int):Bool;

	/** The days in a month — named as C#'s `DateTime.DaysInMonth`; no dialect spells it yet. */
	public static function daysInMonth(year:Int, month:Int):Int;

	/**
		A date built from its parts, as C#'s `new DateTime(y, m, d)` is. `new Date(y, m, d, h, mi, s)`
		says the same inside a lambda, reading a row; with none of its parts read off a row it is
		the date it makes.
	**/
	public static function dateFromParts(year:Int, month:Int, day:Int, ?hour:Int, ?minute:Int, ?second:Int):Date;

	/**
		Calls `name` with `arguments` — a function the library has no word for, because it belongs to
		an extension, to a dialect, or to you:

		```haxe
		.OrderByDesc(p -> Sql.call("word_similarity", p.name, term))
		// ORDER BY word_similarity(t0.name, 'bolt') DESC
		```

		The arguments are ordinary expressions, so columns and values are still the compiler's
		business; only the name is a string, written at the call site, and it has to be an
		identifier. This is not a way to write SQL by hand — a name that is anything other than a
		function's is refused.
	**/
	public static function call<T>(name:String, arguments:haxe.extern.Rest<Dynamic>):T;
}
