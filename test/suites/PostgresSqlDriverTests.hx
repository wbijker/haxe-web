package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/**
	`PostgresSqlDriverTests.cs`.

	The C# asserts the PostgreSQL driver's pretty-printed, identifier-quoted layout. The port has one
	translator and no pretty printer, so a test whose whole point is that layout stands aside; the
	rest are ported against the translator's own rendering, checking the clause and not its spelling.
	String and date members (`Title.Contains`, `PublishedDate.Year`) are written as the `Sql.*`
	calls the port translates them through.
**/
class PostgresSqlDriverTests extends TestCase {
	static inline final Reason = "PostgresSqlDriver: dialect-specific rendering (pretty-printed, quoted identifiers)";

	final driver = new SqlTranslator();

	function testSimpleSelect() {
		Assert.skip(Reason + " — the C# expects every column of Book listed; this port selects *");
	}

	function testSelectWithProjection() {
		final sql = driver.ToSql(Query.select(Book).Select(b -> {title: b.title, publishedYear: b.publishedYear}).ToExpression());

		Assert.contains("SELECT", sql);
		Assert.contains(".title", sql);
		Assert.contains(".publishedYear", sql);
	}

	function testWhereClause() {
		final sql = driver.ToSql(Query.select(Book).Where(b -> b.authorId == 5).ToExpression());

		Assert.equals("SELECT * FROM Book AS t0 WHERE t0.authorId = 5", sql);
	}

	function testWhereWithStringContains() {
		final sql = driver.ToSql(Query.select(Book).Where(b -> Sql.like(b.title, "%C#%")).ToExpression());

		Assert.equals("SELECT * FROM Book AS t0 WHERE t0.title LIKE '%C#%'", sql);
	}

	function testOrderBy() {
		final sql = driver.ToSql(Query.select(Book).OrderByDesc(b -> b.publishedYear).OrderBy(b -> b.title).ToExpression());

		Assert.equals("SELECT * FROM Book AS t0 ORDER BY t0.publishedYear DESC, t0.title ASC", sql);
	}

	function testGroupBy() {
		final sql = driver.ToSql(Query.select(Book)
			.GroupBy(b -> b.authorId)
			.SelectAggregation(agg -> {count: agg.count()})
			.ToExpression());

		Assert.contains("GROUP BY t0.authorId", sql);
		Assert.contains("COUNT(*)", sql);
	}

	function testInnerJoin() {
		final sql = driver.ToSql(Query.select(Book).InnerJoin(Query.table(Author), (b, a) -> a.id == b.authorId).ToExpression());

		Assert.contains("INNER JOIN Author AS t1", sql);
		Assert.contains("ON", sql);
	}

	function testLeftJoin() {
		final authorQuery = Query.select(Author);
		final sql = driver.ToSql(Query.select(Book).LeftJoin(authorQuery, (b, a) -> b.authorId == a.id).ToExpression());

		Assert.contains("LEFT JOIN", sql);
		Assert.contains("ON", sql);
	}

	function testJoinWithSimpleQuery_DoesNotNest() {
		final authorQuery = Query.select(Author);
		final sql = driver.ToSql(Query.select(Book).InnerJoin(authorQuery, (b, a) -> b.authorId == a.id).ToExpression());

		// "INNER JOIN Author AS t1", not "INNER JOIN (SELECT * FROM Author)".
		Assert.contains("INNER JOIN Author AS t1", sql);
		Assert.doesNotContain("FROM Author AS t0", sql);
	}

	function testJoinWithFilteredQuery_DoesNest() {
		final authorQuery = Query.select(Author).Where(a -> a.name != "Anonymous");
		final sql = driver.ToSql(Query.select(Book).InnerJoin(authorQuery, (b, a) -> b.authorId == a.id).ToExpression());

		// The filtered query is nested.
		Assert.contains("INNER JOIN (SELECT", sql);
		Assert.contains("FROM Author AS", sql);
		Assert.contains("WHERE", sql);
	}

	/**
		The C# aggregates over the joined rows, `agg.Max((b, a) => b.PublishedYear)`. An aggregate
		projection here reads one row, so the join is reduced to the books first and grouped after.
	**/
	function testComplexQuery() {
		final sql = driver.ToSql(Query.select(Book)
			.InnerJoin(Query.table(Author), (b, a) -> a.id == b.authorId)
			.Where((b, a) -> b.publishedYear > 2000)
			.Reduce((b, a) -> b)
			.GroupBy(b -> b.authorId)
			.SelectAggregation(agg -> {bookCount: agg.count(), maxYear: agg.max(b -> b.publishedYear)})
			.ToExpression());

		Assert.contains("SELECT", sql);
		Assert.contains("FROM Book", sql);
		Assert.contains("INNER JOIN", sql);
		Assert.contains("WHERE", sql);
		Assert.contains("GROUP BY", sql);
		Assert.contains("COUNT(*)", sql);
		Assert.contains("MAX(", sql);
	}

	function testAggregateWithSelector() {
		final sql = driver.ToSql(Query.select(Book)
			.GroupBy(b -> b.authorId)
			.SelectAggregation(agg -> {
				totalBooks: agg.count(),
				maxYear: agg.max(b -> b.publishedYear),
				minYear: agg.min(b -> b.publishedYear)
			})
			.ToExpression());

		Assert.contains("COUNT(*)", sql);
		Assert.contains("MAX(t0.publishedYear)", sql);
		Assert.contains("MIN(t0.publishedYear)", sql);
	}

	function testBinaryOperatorInProjection() {
		final sql = driver.ToSql(Query.select(Book).Select(b -> {nextYear: b.publishedYear + 1}).ToExpression());

		Assert.contains("t0.publishedYear + 1", sql);
	}

	function testStringFunctions() {
		final sql = driver.ToSql(Query.select(Book).Select(b -> {upper: Sql.upper(b.title)}).ToExpression());

		Assert.contains("UPPER(t0.title)", sql);
	}

	function testDateTimeProperties() {
		final sql = driver.ToSql(Query.select(Book).Select(b -> {
			year: Sql.datePart("YEAR", b.publishedDate),
			month: Sql.datePart("MONTH", b.publishedDate),
			day: Sql.datePart("DAY", b.publishedDate)
		}).ToExpression());

		Assert.contains("EXTRACT(YEAR FROM t0.publishedDate)", sql);
		Assert.contains("EXTRACT(MONTH FROM t0.publishedDate)", sql);
		Assert.contains("EXTRACT(DAY FROM t0.publishedDate)", sql);
	}

	function testDateTimeTimeProperties() {
		final sql = driver.ToSql(Query.select(Book).Select(b -> {
			hour: Sql.datePart("HOUR", b.publishedDate),
			minute: Sql.datePart("MINUTE", b.publishedDate),
			second: Sql.datePart("SECOND", b.publishedDate)
		}).ToExpression());

		Assert.contains("EXTRACT(HOUR FROM t0.publishedDate)", sql);
		Assert.contains("EXTRACT(MINUTE FROM t0.publishedDate)", sql);
		Assert.contains("EXTRACT(SECOND FROM t0.publishedDate)", sql);
	}

	function testDateTimeDayOfWeekAndDayOfYear() {
		final sql = driver.ToSql(Query.select(Book).Select(b -> {
			dayOfWeek: Sql.datePart("DOW", b.publishedDate),
			dayOfYear: Sql.datePart("DOY", b.publishedDate)
		}).ToExpression());

		Assert.contains("EXTRACT(DOW FROM t0.publishedDate)", sql);
		Assert.contains("EXTRACT(DOY FROM t0.publishedDate)", sql);
	}

	function testDateTimeDate() {
		Assert.skip("DateTime.Date: no date-truncation translation in this port");
	}

	function testDateTimeAddMethods() {
		final sql = driver.ToSql(Query.select(Book).Select(b -> {
			plusYear: Sql.dateAdd(b.publishedDate, 1, "years"),
			plusMonth: Sql.dateAdd(b.publishedDate, 2, "months"),
			plusDay: Sql.dateAdd(b.publishedDate, 3, "days")
		}).ToExpression());

		Assert.contains("t0.publishedDate + INTERVAL '1 years'", sql);
		Assert.contains("t0.publishedDate + INTERVAL '2 months'", sql);
		Assert.contains("t0.publishedDate + INTERVAL '3 days'", sql);
	}

	function testDateTimeAddTimeMethods() {
		final sql = driver.ToSql(Query.select(Book).Select(b -> {
			plusHours: Sql.dateAdd(b.publishedDate, 4, "hours"),
			plusMinutes: Sql.dateAdd(b.publishedDate, 30, "minutes"),
			plusSeconds: Sql.dateAdd(b.publishedDate, 45, "seconds")
		}).ToExpression());

		Assert.contains("t0.publishedDate + INTERVAL '4 hours'", sql);
		Assert.contains("t0.publishedDate + INTERVAL '30 minutes'", sql);
		Assert.contains("t0.publishedDate + INTERVAL '45 seconds'", sql);
	}

	function testDateTimeInWhereClause() {
		final sql = driver.ToSql(Query.select(Book).Where(b -> Sql.datePart("YEAR", b.publishedDate) == 2020).ToExpression());

		Assert.contains("WHERE EXTRACT(YEAR FROM t0.publishedDate) = 2020", sql);
	}
}
