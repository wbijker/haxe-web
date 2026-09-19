package suites;

import codequery.DateTimePart;
import codequery.Query;
import codequery.SqlDate;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("trips")
class Trip {
	public var id:Int = 0;
	public var tareDate:SqlDate;
	public var grossDate:SqlDate;

	public function new() {}
}

/**
	`DateOperationTests.cs` — `SqlDate`'s date operations: the ones SQL has and Haxe does not, named
	once and written by each driver in its own dialect. This port renders one PostgreSQL-ish dialect,
	so the assertions on the other three are left out where the PostgreSQL one stands.
**/
class DateOperationTests extends TestCase {
	static function Sql(select:SelectExpression):String {
		return new SqlTranslator().ToSql(select);
	}

	// ---- truncate ------------------------------------------------------------------------------------

	function testTruncate_Postgres_UsesDateTrunc() {
		Assert.contains("DATE_TRUNC('month', t0.tareDate)",
			Sql(Query.select(Trip).Select(r -> r.tareDate.truncate(Month)).ToExpression()));
	}

	function testTruncate_SqlServer_CountsFromTheZeroDate() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testTruncate_MySql_RebuildsTheDate() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testTruncate_Sqlite_UsesAModifier() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	/** A week boundary means different things to different dialects; PostgreSQL says it directly. */
	function testTruncate_ToAWeek_IsRefusedWhereItWouldBeAGuess() {
		Assert.contains("DATE_TRUNC('week'", Sql(Query.select(Trip).Select(r -> r.tareDate.truncate(Week)).ToExpression()));
		// SQL Server's refusal: MssqlSqlDriver is not in this port.
	}

	function testTruncate_ToAQuarter_IsRefusedBySqliteAndMySql() {
		Assert.contains("DATE_TRUNC('quarter'", Sql(Query.select(Trip).Select(r -> r.tareDate.truncate(Quarter)).ToExpression()));
		// The SQL Server spelling and the MySQL and SQLite refusals: those dialects are not in this port.
	}

	// ---- difference ----------------------------------------------------------------------------------

	function testDifference_InDays_EachDialectsOwnWay() {
		Assert.contains("(CAST(t0.grossDate AS DATE) - CAST(t0.tareDate AS DATE))",
			Sql(Query.select(Trip).Select(r -> r.tareDate.differenceTo(r.grossDate, Day)).ToExpression()));
		// SQL Server, MySQL and SQLite: not in this port.
	}

	/** Months are calendar arithmetic, which PostgreSQL has no single function for. */
	function testDifference_InMonths_IsCountedOnTheCalendar() {
		final sql = Sql(Query.select(Trip).Select(r -> r.tareDate.differenceTo(r.grossDate, Month)).ToExpression());

		Assert.contains("EXTRACT(YEAR FROM t0.grossDate) - EXTRACT(YEAR FROM t0.tareDate)", sql);
		Assert.contains("* 12", sql);
	}

	function testDifference_InMonths_IsRefusedBySqlite() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testDifference_InSeconds_Postgres_ComesOffTheEpoch() {
		Assert.contains("CAST(EXTRACT(EPOCH FROM (t0.grossDate - t0.tareDate)) AS INTEGER)",
			Sql(Query.select(Trip).Select(r -> r.tareDate.differenceTo(r.grossDate, Second)).ToExpression()));
	}

	// ---- parts ---------------------------------------------------------------------------------------

	function testPart_Quarter_EachDialectsOwnWay() {
		Assert.contains("EXTRACT(QUARTER FROM t0.tareDate)",
			Sql(Query.select(Trip).Select(r -> r.tareDate.part(Quarter)).ToExpression()));
		// SQL Server, MySQL and SQLite: not in this port.
	}

	function testPart_IsoWeek_SaysIso() {
		Assert.skip("MssqlSqlDriver/MySqlSqlDriver: the ISO week spellings asserted are those dialects' own");
	}

	// ---- end of month, epoch -------------------------------------------------------------------------

	function testEndOfMonth_EachDialectsOwnWay() {
		Assert.contains("(DATE_TRUNC('month', t0.tareDate) + INTERVAL '1 month' - INTERVAL '1 day')",
			Sql(Query.select(Trip).Select(r -> r.tareDate.endOfMonth()).ToExpression()));
		// SQL Server, MySQL and SQLite: not in this port.
	}

	function testEpochSeconds_EachDialectsOwnWay() {
		Assert.contains("EXTRACT(EPOCH FROM t0.tareDate)", Sql(Query.select(Trip).Select(r -> r.tareDate.epochSeconds()).ToExpression()));
		// MySQL, SQLite and SQL Server: not in this port.
	}

	// ---- the operations compose ----------------------------------------------------------------------

	/** An operation is an expression like any other, so it nests and filters. */
	function testAnOperation_IsAnExpressionLikeAnyOther() {
		final sql = Sql(Query.select(Trip)
			.Where(r -> r.tareDate.truncate(Month) == r.grossDate.truncate(Month))
			.ToExpression());

		Assert.contains("WHERE DATE_TRUNC('month', t0.tareDate) = DATE_TRUNC('month', t0.grossDate)", sql);
	}

	function testCalledDirectly_ItThrows() {
		final now:SqlDate = Date.now();
		Assert.throws(() -> now.truncate(Month));
		Assert.throws(() -> now.endOfMonth());
	}
}
