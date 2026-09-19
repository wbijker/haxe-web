package suites;

import codequery.Query;
import codequery.SqlDate;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("shift")
class Shift {
	public var id:Int = 0;

	/** C#'s `DateOnly`. Haxe has one date type, so a date-only column is a `SqlDate` here. */
	public var day:SqlDate;

	/** C#'s `TimeOnly`, likewise. */
	public var startsAt:SqlDate;

	public function new() {}
}

/**
	`DateOnlyTimeOnlyQueryTests.cs`. A database has one date type and one time type, so these read
	and shift by the same functions a timestamp does — which is also all Haxe has: `DateOnly` and
	`TimeOnly` columns are `SqlDate` here, and the SQL is the same.
**/
class DateOnlyTimeOnlyQueryTests extends TestCase {
	static function Sql(select:SelectExpression):String {
		return new SqlTranslator().ToSql(select);
	}

	function testADatesParts_AreTheSameFunctionsADateTimeUses() {
		Assert.contains("EXTRACT(YEAR FROM t0.day)", Sql(Query.select(Shift).Where(s -> s.day.getFullYear() == 2026).ToExpression()));
		Assert.contains("EXTRACT(MONTH FROM t0.day)", Sql(Query.select(Shift).Where(s -> s.day.getMonth() == 3).ToExpression()));
		Assert.contains("EXTRACT(DAY FROM t0.day)", Sql(Query.select(Shift).Where(s -> s.day.getDate() == 9).ToExpression()));
	}

	function testATimesParts_Likewise() {
		Assert.contains("EXTRACT(HOUR FROM t0.startsAt)", Sql(Query.select(Shift).Where(s -> s.startsAt.getHours() == 14).ToExpression()));
		Assert.contains("EXTRACT(MINUTE FROM t0.startsAt)", Sql(Query.select(Shift).Where(s -> s.startsAt.getMinutes() == 30).ToExpression()));
	}

	function testDayOfWeek_Reads() {
		Assert.contains("EXTRACT(DOW FROM t0.day)", Sql(Query.select(Shift).Where(s -> s.day.getDay() == 5).ToExpression()));
	}

	function testADateShifts_ByTheSameFunctions() {
		final sql = Sql(Query.select(Shift).Where(s -> s.day.addDays(7) > new Date(2026, 2, 1, 0, 0, 0)).ToExpression());

		Assert.contains("INTERVAL", sql);
		// A date literal carries its midnight here, since Haxe's Date always has a time.
		Assert.contains("'2026-03-01", sql);
	}

	function testATimeShifts_Too() {
		Assert.contains("INTERVAL", Sql(Query.select(Shift).Where(s -> s.startsAt.addHours(2) > s.startsAt).ToExpression()));
	}

	function testAPropertyThatIsNotADatesPart_SaysSo() {
		Assert.skip("DateOnly.DayNumber: a member the converter refuses is a compile error here, which a test cannot catch");
	}
}
