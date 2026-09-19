package suites;

import codequery.DateFormat;
import codequery.Query;
import codequery.SqlDate;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("trips")
class FormattedTrip {
	public var id:Int = 0;
	public var tareDate:SqlDate;

	public function new() {}
}

/**
	`DateFormatTests.cs` — `SqlDate.format`: a date format named by its parts, so each driver writes
	it in its own tokens. This port renders the PostgreSQL spelling; the others are not in it.
**/
class DateFormatTests extends TestCase {
	static function Sql(select:SelectExpression):String {
		return new SqlTranslator().ToSql(select);
	}

	// ---- the same format, four dialects ----------------------------------------------------------------

	function testPostgres_UsesToChar() {
		final sql = Sql(Query.select(FormattedTrip).Select(r -> {label: r.tareDate.format(f -> f.fullMonth().space().fullYear())}).ToExpression());
		Assert.contains("to_char(t0.tareDate, 'FMMonth YYYY')", sql);
	}

	function testSqlServer_UsesFormat() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testMySql_UsesDateFormat() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testSqlite_UsesStrftime_WithThePatternFirst() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	// ---- literals ------------------------------------------------------------------------------------

	/** A literal containing letters must be protected, or to_char reads it as pattern tokens. */
	function testPostgres_QuotesALiteralWithLetters() {
		final sql = Sql(Query.select(FormattedTrip).Select(r -> {label: r.tareDate.format(f -> f.literal("as at ").fullMonth())}).ToExpression());
		Assert.contains("to_char(t0.tareDate, '\"as at \"FMMonth')", sql);
	}

	/** Punctuation needs no protection there. */
	function testPostgres_LeavesPunctuationAlone() {
		final sql = Sql(Query.select(FormattedTrip).Select(r -> {label: r.tareDate.format(f -> f.literal("::").fullMonth().space().fullYear())}).ToExpression());
		Assert.contains("to_char(t0.tareDate, '::FMMonth YYYY')", sql);
	}

	function testSqlServer_EscapesALiteral() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testMySql_EscapesAPercent() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	// ---- what a dialect cannot do ---------------------------------------------------------------------

	function testSqlite_RefusesAMonthName() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testSqlServer_RefusesTheIsoWeek() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testMySql_RefusesTheQuarter() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	/** PostgreSQL is the one that can express all of them. */
	function testPostgres_SpellsEveryPart() {
		final sql = Sql(Query.select(FormattedTrip).Select(r -> {
			label: r.tareDate.format(f -> f
				.shortDayName().literal(", ").day().space().shortMonth().space().shortYear()
				.space().hour12().literal(":").minute().literal(":").second().literal(".").millisecond()
				.space().amPm().space().utcOffset()
				.space().quarter().space().isoWeek().space().dayOfYear().space().month().space().dayPadded()
				.space().hour24())
		}).ToExpression());

		// ", " carries no letters, so PostgreSQL needs no quoting around it.
		Assert.contains("'FMDy, FMDD FMMon YY HH12:MI:SS.MS AM OF Q IW DDD FMMM DD HH24'", sql);
	}

	// ---- the builder itself --------------------------------------------------------------------------

	function testAFormatThatNamesNothing_IsRefused() {
		final error = Assert.throwsMessage(() -> Sql(Query.select(FormattedTrip).Select(r -> {label: r.tareDate.format(f -> f)}).ToExpression()));
		Assert.contains("names no parts", error);
	}

	function testCalledDirectly_ItThrows() {
		final now:SqlDate = Date.now();
		Assert.throws(() -> now.format(f -> f.fullYear()));
	}
}
