package codequery.sqlexpressions;

/**
	The names of the functions the expression converter produces from a Haxe expression — the ones
	`x.toUpperCase()` or `d.addHours(n)` map onto, as C#'s `SqlFunctions` names them.

	A `SqlFunctionExpression` carries its function as a string, not an enum, because the tree
	describes a *construct* — a call of some function with some arguments — and the set of
	functions is open. A translator spells the names it recognises in its own dialect; a name that
	is not here is the caller naming a database function directly, and renders as a plain call.
**/
class SqlFunctions {
	/**
		Whether `name` is one of the names below — a concept every dialect is expected to have some
		spelling for. A dialect that has none says so; anything else is rendered verbatim as
		`Name(args)`, because there is nothing to translate.
	**/
	public static function IsKnown(name:String):Bool {
		return Names.indexOf(name) >= 0;
	}

	// String functions
	public static inline final Upper = "Upper";
	public static inline final Lower = "Lower";
	public static inline final Trim = "Trim";
	public static inline final TrimStart = "TrimStart";
	public static inline final TrimEnd = "TrimEnd";
	public static inline final Substring = "Substring";
	public static inline final Replace = "Replace";
	public static inline final IndexOf = "IndexOf";
	public static inline final PadLeft = "PadLeft";
	public static inline final PadRight = "PadRight";
	public static inline final Length = "Length";

	// DateTime functions
	public static inline final Year = "Year";
	public static inline final Month = "Month";
	public static inline final Day = "Day";
	public static inline final Hour = "Hour";
	public static inline final Minute = "Minute";
	public static inline final Second = "Second";
	public static inline final DayOfWeek = "DayOfWeek";
	public static inline final DayOfYear = "DayOfYear";
	public static inline final Date = "Date";
	public static inline final AddYears = "AddYears";
	public static inline final AddMonths = "AddMonths";
	public static inline final AddDays = "AddDays";
	public static inline final AddHours = "AddHours";
	public static inline final AddMinutes = "AddMinutes";
	public static inline final AddSeconds = "AddSeconds";

	// Numeric functions
	public static inline final Abs = "Abs";
	public static inline final Sign = "Sign";
	public static inline final Ceiling = "Ceiling";
	public static inline final Floor = "Floor";
	public static inline final Round = "Round";
	public static inline final Truncate = "Truncate";
	public static inline final Power = "Power";
	public static inline final Sqrt = "Sqrt";
	public static inline final Exp = "Exp";
	public static inline final Ln = "Ln";
	public static inline final Log10 = "Log10";

	// Conditional / conversion
	public static inline final Coalesce = "Coalesce";
	public static inline final NullIf = "NullIf";
	public static inline final Greatest = "Greatest";
	public static inline final Least = "Least";

	// String (extended)
	public static inline final Concat = "Concat";
	public static inline final ConcatWs = "ConcatWs";
	public static inline final Left = "Left";
	public static inline final Right = "Right";
	public static inline final Like = "Like";
	public static inline final LikeEscape = "LikeEscape";
	public static inline final ILike = "ILike";
	public static inline final ILikeEscape = "ILikeEscape";

	// Values
	public static inline final Random = "Random";
	public static inline final NewUuid = "NewUuid";

	// Aggregate (extended)
	public static inline final StringAgg = "StringAgg";
	public static inline final PercentileCont = "PercentileCont";
	public static inline final PercentileDisc = "PercentileDisc";
	public static inline final Median = "Median";
	public static inline final Mode = "Mode";
	public static inline final CountFilter = "CountFilter";
	public static inline final SumFilter = "SumFilter";

	// DateTime static methods/properties
	public static inline final Now = "Now";
	public static inline final UtcNow = "UtcNow";
	public static inline final Today = "Today";
	public static inline final DateTimeFromParts = "DateTimeFromParts";
	public static inline final IsLeapYear = "IsLeapYear";
	public static inline final DaysInMonth = "DaysInMonth";
	public static inline final Parse = "Parse";

	// JSON functions — named here as C# names them, so that a dialect refuses them by name.
	public static inline final JsonExtract = "JsonExtract";
	public static inline final JsonExtractText = "JsonExtractText";
	public static inline final JsonContains = "JsonContains";
	public static inline final JsonExists = "JsonExists";
	public static inline final JsonArrayLength = "JsonArrayLength";
	public static inline final JsonType = "JsonType";
	public static inline final JsonKeys = "JsonKeys";
	public static inline final JsonSet = "JsonSet";
	public static inline final JsonRemove = "JsonRemove";
	public static inline final JsonInsert = "JsonInsert";
	public static inline final JsonReplace = "JsonReplace";
	public static inline final JsonMerge = "JsonMerge";
	public static inline final JsonArrayAppend = "JsonArrayAppend";
	public static inline final JsonValid = "JsonValid";

	static final Names = [
		Upper, Lower, Trim, TrimStart, TrimEnd, Substring, Replace, IndexOf, PadLeft, PadRight, Length,
		Year, Month, Day, Hour, Minute, Second, DayOfWeek, DayOfYear, Date,
		AddYears, AddMonths, AddDays, AddHours, AddMinutes, AddSeconds,
		Abs, Sign, Ceiling, Floor, Round, Truncate, Power, Sqrt, Exp, Ln, Log10,
		Coalesce, NullIf, Greatest, Least,
		Concat, ConcatWs, Left, Right, Like, LikeEscape, ILike, ILikeEscape,
		Random, NewUuid,
		StringAgg, PercentileCont, PercentileDisc, Median, Mode, CountFilter, SumFilter,
		Now, UtcNow, Today, DateTimeFromParts, IsLeapYear, DaysInMonth, Parse,
		JsonExtract, JsonExtractText, JsonContains, JsonExists, JsonArrayLength, JsonType, JsonKeys,
		JsonSet, JsonRemove, JsonInsert, JsonReplace, JsonMerge, JsonArrayAppend, JsonValid,
	];
}
