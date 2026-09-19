package suites;

import codequery.Query;
import codequery.Sql;
import codequery.SqlDate;
import codequery.SqlInterval;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("books")
class DatedBook {
	@columnName("created") public var created:SqlDate;
	@columnName("read_at") public var readAt:SqlDate;

	public function new() {}
}

/**
	`DateTimeFunctionsTests.cs` — the `Date` surface a query can use: the members Haxe already has
	(the parts, `Date.now()`), the ones `SqlDate` adds (`addDays`), and the spans they are measured
	in — `SqlInterval`, which becomes SQL's interval.

	The other dialects' spellings are not in this port, which renders one PostgreSQL-ish dialect.
**/
class DateTimeFunctionsTests extends TestCase {
	static function Render(select:SelectExpression):String {
		return new SqlTranslator().ToSql(select);
	}

	static function Where(select:SelectExpression):String {
		final sql = Render(select);
		return sql.substring(sql.indexOf("WHERE ") + 6);
	}

	// ---- a span of time is an interval ----------------------------------------------------------------

	/** The difference of two dates is a span, and it is compared against a span — SQL's interval. */
	function testTheDifferenceOfTwoDates_IsComparedAgainstAnInterval() {
		Assert.equals("NOW() - t0.created > INTERVAL '3 days'",
			Where(Query.select(DatedBook).Where(b -> Date.now() - b.created > SqlInterval.days(3)).ToExpression()));
	}

	function testEachUnitIsNamed() {
		Assert.contains("INTERVAL '2 hours'",
			Where(Query.select(DatedBook).Where(b -> Sql.utcNow() - b.created <= SqlInterval.hours(2)).ToExpression()));

		Assert.contains("INTERVAL '90 minutes'",
			Where(Query.select(DatedBook).Where(b -> b.created > Date.now() - SqlInterval.minutes(90)).ToExpression()));

		Assert.contains("INTERVAL '30 seconds'",
			Where(Query.select(DatedBook).Where(b -> Date.now() - b.created < SqlInterval.seconds(30)).ToExpression()));
	}

	/** A span held in a variable is the same span. */
	function testACapturedSpan() {
		final window = SqlInterval.days(7);

		Assert.contains("INTERVAL '7 days'",
			Where(Query.select(DatedBook).Where(b -> Date.now() - b.created > window).ToExpression()));
	}

	/** A span that is not whole days is written in the largest unit that divides it evenly. */
	function testASpanThatIsNotWholeDays() {
		Assert.contains("INTERVAL '3150 minutes'",
			Where(Query.select(DatedBook).Where(b -> Date.now() - b.created > SqlInterval.of(2, 4, 30, 0)).ToExpression()));
	}

	/** An interval is a value like any other: it adds to and subtracts from a date. */
	function testIntervalArithmetic() {
		Assert.contains("t0.created + INTERVAL '1 days'", Render(Query.select(DatedBook).Select(b -> b.created + SqlInterval.days(1)).ToExpression()));
		Assert.contains("t0.created - INTERVAL '6 hours'", Render(Query.select(DatedBook).Select(b -> b.created - SqlInterval.hours(6)).ToExpression()));
	}

	// ---- the dialects without a duration type say the same thing another way ---------------------------

	function testMySql_AddsWithAKeywordAndComparesWithACount() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testMySql_CountsMicrosecondsForAFinerSpan() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testSqlServer_Counts() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_CountsMillisecondsForAFinerSpan() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlite_UsesModifiersAndJulianDays() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testTheSpanOnTheLeftReadsTheSame() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testASpanOnItsOwn_IsStillRefused() {
		Assert.skip("MssqlSqlDriver/SqliteSqlDriver: the refusal is those dialects', which have no interval");
	}

	// ---- the parts Haxe already names -----------------------------------------------------------------

	function testTheDateParts() {
		Assert.contains("EXTRACT(YEAR FROM t0.created)", Render(Query.select(DatedBook).Select(b -> b.created.getFullYear()).ToExpression()));
		Assert.contains("EXTRACT(MONTH FROM t0.created)", Render(Query.select(DatedBook).Select(b -> b.created.getMonth()).ToExpression()));
		Assert.contains("EXTRACT(DAY FROM t0.created)", Render(Query.select(DatedBook).Select(b -> b.created.getDate()).ToExpression()));
		Assert.contains("EXTRACT(HOUR FROM t0.created)", Render(Query.select(DatedBook).Select(b -> b.created.getHours()).ToExpression()));
		Assert.contains("EXTRACT(MINUTE FROM t0.created)", Render(Query.select(DatedBook).Select(b -> b.created.getMinutes()).ToExpression()));
		Assert.contains("EXTRACT(SECOND FROM t0.created)", Render(Query.select(DatedBook).Select(b -> b.created.getSeconds()).ToExpression()));
		Assert.contains("EXTRACT(DOW FROM t0.created)", Render(Query.select(DatedBook).Select(b -> b.created.getDay()).ToExpression()));
		Assert.contains("EXTRACT(DOY FROM t0.created)", Render(Query.select(DatedBook).Select(b -> b.created.dayOfYear()).ToExpression()));
		Assert.contains("DATE(t0.created)", Render(Query.select(DatedBook).Select(b -> b.created.date()).ToExpression()));
	}

	/** A part read off a column that may be absent reads the column. */
	function testAPartOfANullableColumn() {
		Assert.contains("EXTRACT(YEAR FROM t0.read_at)", Render(Query.select(DatedBook).Select(b -> b.readAt.getFullYear()).ToExpression()));
	}

	// ---- the Add methods, which are interval arithmetic -----------------------------------------------

	function testTheAddMethods() {
		Assert.contains("(t0.created + INTERVAL '1 years')", Render(Query.select(DatedBook).Select(b -> b.created.addYears(1)).ToExpression()));
		Assert.contains("(t0.created + INTERVAL '2 months')", Render(Query.select(DatedBook).Select(b -> b.created.addMonths(2)).ToExpression()));
		Assert.contains("(t0.created + INTERVAL '3 days')", Render(Query.select(DatedBook).Select(b -> b.created.addDays(3)).ToExpression()));
		Assert.contains("(t0.created + INTERVAL '4 hours')", Render(Query.select(DatedBook).Select(b -> b.created.addHours(4)).ToExpression()));
		Assert.contains("(t0.created + INTERVAL '5 minutes')", Render(Query.select(DatedBook).Select(b -> b.created.addMinutes(5)).ToExpression()));
		Assert.contains("(t0.created + INTERVAL '6 seconds')", Render(Query.select(DatedBook).Select(b -> b.created.addSeconds(6)).ToExpression()));
	}

	// ---- the clock ------------------------------------------------------------------------------------

	function testTheClockIsTheDatabases() {
		Assert.contains("NOW()", Render(Query.select(DatedBook).Select(b -> Date.now()).ToExpression()));
		Assert.contains("(NOW() AT TIME ZONE 'UTC')", Render(Query.select(DatedBook).Select(b -> Sql.utcNow()).ToExpression()));
		Assert.contains("CURRENT_DATE", Render(Query.select(DatedBook).Select(b -> Sql.today()).ToExpression()));
	}

	// ---- what is mapped but has no PostgreSQL translation ---------------------------------------------

	/** Recognised as functions but not spelled by the dialect, so they refuse by name. */
	function testTheStaticsThatAreNotTranslatedYet() {
		Assert.throws(() -> Render(Query.select(DatedBook).Select(b -> Sql.isLeapYear(2024)).ToExpression()));
		Assert.throws(() -> Render(Query.select(DatedBook).Select(b -> Sql.daysInMonth(2024, 2)).ToExpression()));
		Assert.throws(() -> Render(Query.select(DatedBook).Select(b -> Date.fromString("2026-01-01")).ToExpression()));
	}
}
