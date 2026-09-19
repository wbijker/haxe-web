package codequery.sqldrivers;

import codequery.DateFormat;
import codequery.DateTimePart;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.DateFormatSqlExpression;
import codequery.sqlexpressions.DateOperationSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.IntervalSqlExpression;
import codequery.sqlexpressions.SqlFunctionExpression;
import codequery.sqlexpressions.SqlFunctions;
import codequery.sqlexpressions.StringOperationExpression;

/**
	How the translator spells what the converter names in the abstract: the functions of
	`SqlFunctions`, a string test, a date operation, a date format, a span of time.

	The spellings are PostgreSQL's, which is the dialect this port renders; C# keeps one such set
	per driver. A name core defined that this dialect cannot spell is refused by name, rather than
	rendered as a call the database would not know.
**/
class FunctionRendering {
	static inline final Dialect = "SqlTranslator";

	/** A known function in this dialect's spelling, or null where the name is not one core knows. */
	public static function KnownFunction(e:SqlFunctionExpression, translator:SqlTranslator):Null<String> {
		if (!SqlFunctions.IsKnown(e.Name)) {
			return null;
		}
		final arg = (index:Int) -> translator.RenderExpression(e.Arguments[index]);
		final list = () -> e.Arguments.map(translator.RenderExpression).join(", ");
		final hasTwo = e.Arguments.length > 1;

		return switch e.Name {
			case SqlFunctions.Upper: 'UPPER(${arg(0)})';
			case SqlFunctions.Lower: 'LOWER(${arg(0)})';
			case SqlFunctions.Trim: 'TRIM(${arg(0)})';
			case SqlFunctions.TrimStart: 'LTRIM(${arg(0)})';
			case SqlFunctions.TrimEnd: 'RTRIM(${arg(0)})';
			case SqlFunctions.Length: 'LENGTH(${arg(0)})';
			// SUBSTRING counts from one where the caller counted from zero.
			case SqlFunctions.Substring: hasTwo && e.Arguments.length > 2
				? 'SUBSTRING(${arg(0)} FROM (${arg(1)} + 1) FOR ${arg(2)})'
				: 'SUBSTRING(${arg(0)} FROM (${arg(1)} + 1))';
			case SqlFunctions.Replace: 'REPLACE(${arg(0)}, ${arg(1)}, ${arg(2)})';
			case SqlFunctions.IndexOf: '(POSITION(${arg(1)} IN ${arg(0)}) - 1)';
			case SqlFunctions.PadLeft: 'LPAD(${list()})';
			case SqlFunctions.PadRight: 'RPAD(${list()})';

			case SqlFunctions.Year: 'EXTRACT(YEAR FROM ${arg(0)})';
			case SqlFunctions.Month: 'EXTRACT(MONTH FROM ${arg(0)})';
			case SqlFunctions.Day: 'EXTRACT(DAY FROM ${arg(0)})';
			case SqlFunctions.Hour: 'EXTRACT(HOUR FROM ${arg(0)})';
			case SqlFunctions.Minute: 'EXTRACT(MINUTE FROM ${arg(0)})';
			case SqlFunctions.Second: 'EXTRACT(SECOND FROM ${arg(0)})';
			case SqlFunctions.DayOfWeek: 'EXTRACT(DOW FROM ${arg(0)})';
			case SqlFunctions.DayOfYear: 'EXTRACT(DOY FROM ${arg(0)})';
			case SqlFunctions.Date: 'DATE(${arg(0)})';

			case SqlFunctions.AddYears: Added(e, "years", translator);
			case SqlFunctions.AddMonths: Added(e, "months", translator);
			case SqlFunctions.AddDays: Added(e, "days", translator);
			case SqlFunctions.AddHours: Added(e, "hours", translator);
			case SqlFunctions.AddMinutes: Added(e, "minutes", translator);
			case SqlFunctions.AddSeconds: Added(e, "seconds", translator);

			case SqlFunctions.Now: "NOW()";
			case SqlFunctions.UtcNow: "(NOW() AT TIME ZONE 'UTC')";
			case SqlFunctions.Today: "CURRENT_DATE";

			case SqlFunctions.Coalesce: 'COALESCE(${list()})';
			case SqlFunctions.NullIf: 'NULLIF(${arg(0)}, ${arg(1)})';
			case SqlFunctions.Greatest: 'GREATEST(${list()})';
			case SqlFunctions.Least: 'LEAST(${list()})';
			case SqlFunctions.Abs: 'ABS(${arg(0)})';
			case SqlFunctions.Sign: 'SIGN(${arg(0)})';
			case SqlFunctions.Ceiling: 'CEIL(${arg(0)})';
			case SqlFunctions.Floor: 'FLOOR(${arg(0)})';
			case SqlFunctions.Round: hasTwo ? 'ROUND(${arg(0)}, ${arg(1)})' : 'ROUND(${arg(0)})';
			case SqlFunctions.Truncate: hasTwo ? 'TRUNC(${arg(0)}, ${arg(1)})' : 'TRUNC(${arg(0)})';
			case SqlFunctions.Power: 'POWER(${arg(0)}, ${arg(1)})';
			case SqlFunctions.Sqrt: 'SQRT(${arg(0)})';
			case SqlFunctions.Exp: 'EXP(${arg(0)})';
			case SqlFunctions.Ln: 'LN(${arg(0)})';
			case SqlFunctions.Log10: 'LOG(${arg(0)})';

			case SqlFunctions.Concat: '(${e.Arguments.map(translator.RenderExpression).join(" || ")})';
			case SqlFunctions.ConcatWs: 'CONCAT_WS(${list()})';
			case SqlFunctions.Left: 'LEFT(${arg(0)}, ${arg(1)})';
			case SqlFunctions.Right: 'RIGHT(${arg(0)}, ${arg(1)})';
			case SqlFunctions.Like: '(${arg(0)} LIKE ${arg(1)})';
			case SqlFunctions.LikeEscape: '(${arg(0)} LIKE ${arg(1)} ESCAPE ${arg(2)})';
			case SqlFunctions.ILike: '(${arg(0)} ILIKE ${arg(1)})';
			case SqlFunctions.ILikeEscape: '(${arg(0)} ILIKE ${arg(1)} ESCAPE ${arg(2)})';

			case SqlFunctions.Random: "random()";
			case SqlFunctions.NewUuid: "gen_random_uuid()";

			case SqlFunctions.StringAgg: 'STRING_AGG(${arg(0)}, ${arg(1)})';
			case SqlFunctions.PercentileCont: 'percentile_cont(${arg(0)}) WITHIN GROUP (ORDER BY ${arg(1)})';
			case SqlFunctions.PercentileDisc: 'percentile_disc(${arg(0)}) WITHIN GROUP (ORDER BY ${arg(1)})';
			case SqlFunctions.Median: 'percentile_cont(0.5) WITHIN GROUP (ORDER BY ${arg(0)})';
			case SqlFunctions.Mode: 'mode() WITHIN GROUP (ORDER BY ${arg(0)})';
			case SqlFunctions.CountFilter: 'count(*) FILTER (WHERE ${arg(0)})';
			case SqlFunctions.SumFilter: 'sum(${arg(0)}) FILTER (WHERE ${arg(1)})';

			// A name core defined is a concept this dialect ought to spell somehow — say so if it
			// cannot, rather than emitting a call the database has never heard of.
			case _: throw 'Function ${e.Name} is not supported by $Dialect';
		}
	}

	/** `(x + INTERVAL 'n unit')` — the `Add*` functions, which are interval arithmetic. */
	static function Added(e:SqlFunctionExpression, unit:String, translator:SqlTranslator):String {
		return '(${translator.RenderExpression(e.Arguments[0])} + INTERVAL \'${translator.RenderExpression(e.Arguments[1])} $unit\')';
	}

	/**
		`(operand LIKE pattern)`. A pattern written at the call site becomes the literal it is, wildcards
		added; anything else — a search term held in a variable, another column — is concatenated with
		the wildcards instead, so the value stays a value.
	**/
	public static function StringOperation(e:StringOperationExpression, translator:SqlTranslator):String {
		final operand = translator.RenderExpression(e.Operand);
		final constant = Std.downcast(cast e.Pattern, ConstSqlExpression);
		final written = constant == null ? null : switch constant.Value {
			case SqlConstString(v): v;
			case _: null;
		}
		if (written != null) {
			final escaped = StringTools.replace(written, "'", "''");
			final pattern = switch e.OperationType {
				case Contains: '\'%$escaped%\'';
				case StartsWith: '\'$escaped%\'';
				case EndsWith: '\'%$escaped\'';
			}
			return '($operand LIKE $pattern)';
		}

		final wildcard = new ConstSqlExpression(SqlConstString("%"));
		final parts:Array<ISqlExpression> = switch e.OperationType {
			case Contains: [wildcard, e.Pattern, wildcard];
			case StartsWith: [e.Pattern, wildcard];
			case EndsWith: [wildcard, e.Pattern];
		}
		return '($operand LIKE ${translator.RenderExpression(new SqlFunctionExpression(SqlFunctions.Concat, parts))})';
	}

	/**
		`date_trunc`, interval arithmetic and `EXTRACT` — PostgreSQL says all of these directly, except
		a difference, which it has no single function for: a day difference is date subtraction, and
		the rest are counted off the epoch or the calendar.
	**/
	public static function DateOperation(e:DateOperationSqlExpression, translator:SqlTranslator):String {
		final value = translator.RenderExpression(e.Value);
		return switch e.Operation {
			case Truncate: 'DATE_TRUNC(\'${TruncUnit(e)}\', $value)';
			case Part: 'EXTRACT(${PartName(e)} FROM $value)';
			case EndOfMonth: '(DATE_TRUNC(\'month\', $value) + INTERVAL \'1 month\' - INTERVAL \'1 day\')';
			case EpochSeconds: 'CAST(EXTRACT(EPOCH FROM $value) AS BIGINT)';
			case Difference: DifferenceOf(e, value, translator.RenderExpression(e.Other));
		}
	}

	/** The error for a part this dialect cannot do the operation in. */
	static function UnsupportedDatePart(e:DateOperationSqlExpression):String {
		return '$Dialect cannot ${e.Operation} by ${e.Part}: the dialect has no way to say it. '
			+ 'Choose another part, or compute it from the ones it has.';
	}

	static function TruncUnit(e:DateOperationSqlExpression):String {
		return switch e.Part {
			case Year: "year";
			case Quarter: "quarter";
			case Month: "month";
			case Week | IsoWeek: "week";
			case Day: "day";
			case Hour: "hour";
			case Minute: "minute";
			case Second: "second";
		}
	}

	static function PartName(e:DateOperationSqlExpression):String {
		return switch e.Part {
			case Year: "YEAR";
			case Quarter: "QUARTER";
			case Month: "MONTH";
			case Week | IsoWeek: "WEEK";
			case Day: "DAY";
			case Hour: "HOUR";
			case Minute: "MINUTE";
			case Second: "SECOND";
		}
	}

	/**
		Whole parts between two dates. Days are date subtraction; smaller units come off the epoch;
		months and years are counted on the calendar, so they agree with what DATEDIFF means elsewhere.
	**/
	static function DifferenceOf(e:DateOperationSqlExpression, from:String, to:String):String {
		return switch e.Part {
			case Day: '(CAST($to AS DATE) - CAST($from AS DATE))';
			case Hour: 'CAST(EXTRACT(EPOCH FROM ($to - $from)) / 3600 AS INTEGER)';
			case Minute: 'CAST(EXTRACT(EPOCH FROM ($to - $from)) / 60 AS INTEGER)';
			case Second: 'CAST(EXTRACT(EPOCH FROM ($to - $from)) AS INTEGER)';
			case Month: 'CAST((EXTRACT(YEAR FROM $to) - EXTRACT(YEAR FROM $from)) * 12 '
				+ '+ (EXTRACT(MONTH FROM $to) - EXTRACT(MONTH FROM $from)) AS INTEGER)';
			case Quarter: 'CAST(((EXTRACT(YEAR FROM $to) - EXTRACT(YEAR FROM $from)) * 12 '
				+ '+ (EXTRACT(MONTH FROM $to) - EXTRACT(MONTH FROM $from))) / 3 AS INTEGER)';
			case Year: 'CAST(EXTRACT(YEAR FROM $to) - EXTRACT(YEAR FROM $from) AS INTEGER)';
			case Week | IsoWeek: throw UnsupportedDatePart(e);
		}
	}

	/**
		`to_char(value, pattern)`. The `FM` prefix drops the padding PostgreSQL adds by default, so a
		month name is `August` rather than `August   `. A literal is wrapped in double quotes when it
		contains a letter, which to_char would otherwise read as pattern tokens.
	**/
	public static function DateFormat(e:DateFormatSqlExpression, translator:SqlTranslator):String {
		var pattern = "";
		for (part in e.Parts) {
			pattern += switch part.Token {
				case Literal: QuotedLiteral(part.Text == null ? "" : part.Text);
				case FullMonth: "FMMonth";
				case ShortMonth: "FMMon";
				case MonthPadded: "MM";
				case Month: "FMMM";
				case FullYear: "YYYY";
				case ShortYear: "YY";
				case DayPadded: "DD";
				case Day: "FMDD";
				case FullDayName: "FMDay";
				case ShortDayName: "FMDy";
				case DayOfYear: "DDD";
				case Quarter: "Q";
				case IsoWeek: "IW";
				case Hour24: "HH24";
				case Hour12: "HH12";
				case Minute: "MI";
				case Second: "SS";
				case Millisecond: "MS";
				case AmPm: "AM";
				case UtcOffset: "OF";
			}
		}
		final literal = translator.RenderExpression(new ConstSqlExpression(SqlConstString(pattern)));
		return 'to_char(${translator.RenderExpression(e.Value)}, $literal)';
	}

	static function QuotedLiteral(text:String):String {
		if (text.length == 0) {
			return "";
		}
		// Letters would be read as tokens; double quotes make to_char pass the text through.
		if (!~/[A-Za-z]/.match(text)) {
			return text;
		}
		final quote = "\"";
		return quote + StringTools.replace(text, quote, "\\" + quote) + quote;
	}

	/**
		A span of time, as standard SQL and PostgreSQL write one: `INTERVAL '3 days'`. A span that is
		not a whole number of one unit is written out in full (`INTERVAL '2 days 04:30:00'`), which
		PostgreSQL reads as well as it reads the short form.
	**/
	public static function Interval(e:IntervalSqlExpression):String {
		final whole = e.WholeUnits;
		if (whole != null) {
			final unit = Std.string(whole.part).toLowerCase();
			return "INTERVAL '" + whole.count + " " + unit + "s'";
		}
		final total = e.Milliseconds;
		final days = Math.floor(total / 86400000.0);
		var rest = total - days * 86400000.0;
		final hours = Math.floor(rest / 3600000.0);
		rest -= hours * 3600000.0;
		final minutes = Math.floor(rest / 60000.0);
		rest -= minutes * 60000.0;
		final seconds = Math.floor(rest / 1000.0);
		final milliseconds = Std.int(rest - seconds * 1000.0);
		final time = '${Pad(hours)}:${Pad(minutes)}:${Pad(seconds)}' + (milliseconds == 0 ? "" : "." + Pad(milliseconds, 3));
		return days == 0 ? "INTERVAL '" + time + "'" : "INTERVAL '" + days + " days " + time + "'";
	}

	static function Pad(value:Float, width:Int = 2):String {
		return StringTools.lpad(Std.string(Std.int(value)), "0", width);
	}
}
