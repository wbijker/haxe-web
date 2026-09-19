package codequery;

/** One piece of a date format: a named part of the date, or a literal to put between them. */
enum DateFormatToken {
	/** Text carried through as itself. */
	Literal;

	/** The month's full name — `August`. */
	FullMonth;

	/** The month's short name — `Aug`. */
	ShortMonth;

	/** The month as a number, zero-padded — `08`. */
	MonthPadded;

	/** The month as a number — `8`. */
	Month;

	/** The four-digit year — `2026`. */
	FullYear;

	/** The last two digits of the year — `26`. */
	ShortYear;

	/** The day of the month, zero-padded — `07`. */
	DayPadded;

	/** The day of the month — `7`. */
	Day;

	/** The weekday's full name — `Monday`. */
	FullDayName;

	/** The weekday's short name — `Mon`. */
	ShortDayName;

	/** The day of the year — `219`. */
	DayOfYear;

	/** The quarter — `3`. */
	Quarter;

	/** The ISO week of the year — `34`. */
	IsoWeek;

	/** The hour on a 24-hour clock, zero-padded — `14`. */
	Hour24;

	/** The hour on a 12-hour clock, zero-padded — `02`. */
	Hour12;

	/** The minute, zero-padded — `05`. */
	Minute;

	/** The second, zero-padded — `09`. */
	Second;

	/** The fractional second — `123`. */
	Millisecond;

	/** AM or PM. */
	AmPm;

	/** The offset from UTC — `+02:00`. */
	UtcOffset;
}

/** One part of a date format: a token, and the text when that token is a literal. */
class DateFormatPart {
	public final Token:DateFormatToken;

	/** The literal text, for `Literal`; null otherwise. */
	public final Text:Null<String>;

	public function new(token:DateFormatToken, ?text:String) {
		this.Token = token;
		this.Text = text;
	}
}

/**
	Describes a date format by naming its parts rather than spelling a dialect's tokens:

	```haxe
	r.tareDate.format(f -> f.fullMonth().space().fullYear())
	// to_char(t0.tareDate, 'FMMonth YYYY')
	```

	Every dialect writes these differently — `FMMonth`, `MMMM`, `%M` — and a format string written
	for one is silently wrong on another. Naming the parts moves that knowledge into the driver,
	where the one that cannot express a part says so instead of rendering something else.
**/
interface IDateFormat {
	/** Text carried through as itself: separators, words, punctuation. */
	function literal(text:String):IDateFormat;

	/** A single space. */
	function space():IDateFormat;

	function fullMonth():IDateFormat;
	function shortMonth():IDateFormat;
	function monthPadded():IDateFormat;
	function month():IDateFormat;

	function fullYear():IDateFormat;
	function shortYear():IDateFormat;

	function dayPadded():IDateFormat;
	function day():IDateFormat;
	function fullDayName():IDateFormat;
	function shortDayName():IDateFormat;
	function dayOfYear():IDateFormat;

	function quarter():IDateFormat;
	function isoWeek():IDateFormat;

	function hour24():IDateFormat;
	function hour12():IDateFormat;
	function minute():IDateFormat;
	function second():IDateFormat;
	function millisecond():IDateFormat;
	function amPm():IDateFormat;

	function utcOffset():IDateFormat;
}

/**
	The `IDateFormat` the converter hands the caller's builder: it records what it is asked for,
	in order, and that list is what the driver renders.
**/
class DateFormatRecorder implements IDateFormat {
	public final Parts:Array<DateFormatPart> = [];

	public function new() {}

	/** The parts a format names, by running it over a recorder. A format naming nothing is refused. */
	public static function Record(format:IDateFormat->IDateFormat):Array<DateFormatPart> {
		final recorder = new DateFormatRecorder();
		format(recorder);
		if (recorder.Parts.length == 0) {
			throw "The date format names no parts: f -> f.fullMonth().space().fullYear(), for example.";
		}
		return recorder.Parts;
	}

	function Add(token:DateFormatToken, ?text:String):IDateFormat {
		Parts.push(new DateFormatPart(token, text));
		return this;
	}

	public function literal(text:String):IDateFormat return Add(Literal, text);
	public function space():IDateFormat return Add(Literal, " ");

	public function fullMonth():IDateFormat return Add(FullMonth);
	public function shortMonth():IDateFormat return Add(ShortMonth);
	public function monthPadded():IDateFormat return Add(MonthPadded);
	public function month():IDateFormat return Add(Month);

	public function fullYear():IDateFormat return Add(FullYear);
	public function shortYear():IDateFormat return Add(ShortYear);

	public function dayPadded():IDateFormat return Add(DayPadded);
	public function day():IDateFormat return Add(Day);
	public function fullDayName():IDateFormat return Add(FullDayName);
	public function shortDayName():IDateFormat return Add(ShortDayName);
	public function dayOfYear():IDateFormat return Add(DayOfYear);

	public function quarter():IDateFormat return Add(Quarter);
	public function isoWeek():IDateFormat return Add(IsoWeek);

	public function hour24():IDateFormat return Add(Hour24);
	public function hour12():IDateFormat return Add(Hour12);
	public function minute():IDateFormat return Add(Minute);
	public function second():IDateFormat return Add(Second);
	public function millisecond():IDateFormat return Add(Millisecond);
	public function amPm():IDateFormat return Add(AmPm);

	public function utcOffset():IDateFormat return Add(UtcOffset);
}
