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
}
