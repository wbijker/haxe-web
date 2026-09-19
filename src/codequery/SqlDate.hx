package codequery;

/**
	A date a query can compare.

	C#'s `DateTime` carries its comparisons, so `b.CheckIn < b.CheckOut` is ordinary C#. Haxe's
	`Date` does not, and a predicate has to type before it can be converted — so without these a
	date could only ever be tested for equality. Converting to and from `Date` is free.

	The methods below are the operations SQL has and `Date` does not — the parts .NET names
	(`addDays`, `dayOfYear`), the ones C#'s `DateTimeSqlExtensions` adds (`truncate`, `part`,
	`differenceTo`, `endOfMonth`, `epochSeconds`) and `format`. They are translated to SQL when
	written inside a query lambda and never run: called outside one they say so. `Date`'s own
	methods are forwarded, so `b.created.getFullYear()` reads the year both here and in SQL.
**/
@:forward
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

	@:op(A == B) static function eq(a:SqlDate, b:SqlDate):Bool {
		return (a : Date).getTime() == (b : Date).getTime();
	}

	@:op(A != B) static function neq(a:SqlDate, b:SqlDate):Bool {
		return (a : Date).getTime() != (b : Date).getTime();
	}

	/** The span from `b` to `a`, which is what `SqlInterval` measures. */
	@:op(A - B) static function difference(a:SqlDate, b:SqlDate):SqlInterval {
		return new SqlInterval((a : Date).getTime() - (b : Date).getTime());
	}

	/** The date a span later. */
	@:op(A + B) static function plus(a:SqlDate, span:SqlInterval):SqlDate {
		return Date.fromTime((a : Date).getTime() + span.Milliseconds);
	}

	/** The date a span earlier. */
	@:op(A - B) static function minus(a:SqlDate, span:SqlInterval):SqlDate {
		return Date.fromTime((a : Date).getTime() - span.Milliseconds);
	}

	// ---- translated to SQL, never run --------------------------------------------------------

	static function TranslationOnly(member:String):String {
		return '$member is translated to SQL and cannot be executed in Haxe; use it inside a query expression.';
	}

	/** The day of the year, 1 to 366 — `EXTRACT(DOY FROM x)`. */
	public function dayOfYear():Int throw TranslationOnly("dayOfYear");

	/** The date with its time dropped — `DATE(x)`. */
	public function date():SqlDate throw TranslationOnly("date");

	/** `x + INTERVAL 'n years'`. */
	public function addYears(count:Int):SqlDate throw TranslationOnly("addYears");

	/** `x + INTERVAL 'n months'`. */
	public function addMonths(count:Int):SqlDate throw TranslationOnly("addMonths");

	/** `x + INTERVAL 'n days'`. */
	public function addDays(count:Int):SqlDate throw TranslationOnly("addDays");

	/** `x + INTERVAL 'n hours'`. */
	public function addHours(count:Int):SqlDate throw TranslationOnly("addHours");

	/** `x + INTERVAL 'n minutes'`. */
	public function addMinutes(count:Int):SqlDate throw TranslationOnly("addMinutes");

	/** `x + INTERVAL 'n seconds'`. */
	public function addSeconds(count:Int):SqlDate throw TranslationOnly("addSeconds");

	/**
		The start of the `part` the date falls in: `truncate(Month)` of the 17th is the 1st at
		midnight. PostgreSQL's `date_trunc`, and each other dialect's way round to it.
	**/
	public function truncate(part:DateTimePart):SqlDate throw TranslationOnly("truncate");

	/**
		Whole `part`s from this date to `other` — the SQL `DATEDIFF(part, this, other)`, counted the
		same way whichever dialect renders it.
	**/
	public function differenceTo(other:SqlDate, part:DateTimePart):Int throw TranslationOnly("differenceTo");

	/**
		The `part` read off the date as a number. Useful for the parts `Date` has no method for —
		the quarter, the ISO week — the rest being `getFullYear()` and friends.
	**/
	public function part(part:DateTimePart):Int throw TranslationOnly("part");

	/** The last day of the date's month, at midnight. */
	public function endOfMonth():SqlDate throw TranslationOnly("endOfMonth");

	/** Seconds since 1970-01-01 UTC. */
	public function epochSeconds():Float throw TranslationOnly("epochSeconds");

	/** The date, formatted as `format` describes — see `IDateFormat`. */
	public function format(format:codequery.DateFormat.IDateFormat->codequery.DateFormat.IDateFormat):String
		throw TranslationOnly("format");
}
