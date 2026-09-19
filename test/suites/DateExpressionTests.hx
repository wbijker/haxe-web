package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/**
	`DateExpressionTests.cs`. C#'s `DateTime` members read as `Date`'s here — `getFullYear()` for
	`Year`, `getDay()` for `DayOfWeek` — and what `Date` has no member for is on `SqlDate` or `Sql`.
**/
class DateExpressionTests extends TestCase {
	// DateTime property accessors

	function testYear() {
		final func = Query.select(Book).Select(b -> b.publishedDate.getFullYear()).ToExpression().selectionAt(0).call(SqlFunctions.Year);
		Assert.single(func.Arguments).column("publishedDate");
	}

	function testMonth() {
		final func = Query.select(Book).Select(b -> b.publishedDate.getMonth()).ToExpression().selectionAt(0).call(SqlFunctions.Month);
		Assert.single(func.Arguments);
	}

	function testDay() {
		final func = Query.select(Book).Select(b -> b.publishedDate.getDate()).ToExpression().selectionAt(0).call(SqlFunctions.Day);
		Assert.single(func.Arguments);
	}

	function testHour() {
		final func = Query.select(Book).Select(b -> b.publishedDate.getHours()).ToExpression().selectionAt(0).call(SqlFunctions.Hour);
		Assert.single(func.Arguments);
	}

	function testMinute() {
		final func = Query.select(Book).Select(b -> b.publishedDate.getMinutes()).ToExpression().selectionAt(0).call(SqlFunctions.Minute);
		Assert.single(func.Arguments);
	}

	function testSecond() {
		final func = Query.select(Book).Select(b -> b.publishedDate.getSeconds()).ToExpression().selectionAt(0).call(SqlFunctions.Second);
		Assert.single(func.Arguments);
	}

	function testDayOfWeek() {
		final func = Query.select(Book).Select(b -> b.publishedDate.getDay()).ToExpression().selectionAt(0).call(SqlFunctions.DayOfWeek);
		Assert.single(func.Arguments);
	}

	function testDayOfYear() {
		final func = Query.select(Book).Select(b -> b.publishedDate.dayOfYear()).ToExpression().selectionAt(0).call(SqlFunctions.DayOfYear);
		Assert.single(func.Arguments);
	}

	function testDate() {
		final func = Query.select(Book).Select(b -> b.publishedDate.date()).ToExpression().selectionAt(0).call(SqlFunctions.Date);
		Assert.single(func.Arguments);
	}

	// DateTime methods

	function testAddYears() {
		final func = Query.select(Book).Select(b -> b.publishedDate.addYears(1)).ToExpression().selectionAt(0).call(SqlFunctions.AddYears);
		Assert.count(2, func.Arguments); // operand + years
		func.Arguments[0].column("publishedDate");
		Assert.isTrue(func.Arguments[1].constant().Value.match(SqlConstInt(1)));
	}

	function testAddMonths() {
		final func = Query.select(Book).Select(b -> b.publishedDate.addMonths(6)).ToExpression().selectionAt(0).call(SqlFunctions.AddMonths);
		Assert.count(2, func.Arguments);
	}

	function testAddDays() {
		final func = Query.select(Book).Select(b -> b.publishedDate.addDays(30)).ToExpression().selectionAt(0).call(SqlFunctions.AddDays);
		Assert.count(2, func.Arguments);
	}

	function testAddHours() {
		final func = Query.select(Book).Select(b -> b.publishedDate.addHours(12)).ToExpression().selectionAt(0).call(SqlFunctions.AddHours);
		Assert.count(2, func.Arguments);
	}

	function testAddMinutes() {
		final func = Query.select(Book).Select(b -> b.publishedDate.addMinutes(30)).ToExpression().selectionAt(0).call(SqlFunctions.AddMinutes);
		Assert.count(2, func.Arguments);
	}

	function testAddSeconds() {
		final func = Query.select(Book).Select(b -> b.publishedDate.addSeconds(45)).ToExpression().selectionAt(0).call(SqlFunctions.AddSeconds);
		Assert.count(2, func.Arguments);
	}

	// DateTime static properties

	function testNow() {
		final func = Query.select(Book).Select(b -> Date.now()).ToExpression().selectionAt(0).call(SqlFunctions.Now);
		Assert.empty(func.Arguments);
	}

	function testUtcNow() {
		final func = Query.select(Book).Select(b -> Sql.utcNow()).ToExpression().selectionAt(0).call(SqlFunctions.UtcNow);
		Assert.empty(func.Arguments);
	}

	function testToday() {
		final func = Query.select(Book).Select(b -> Sql.today()).ToExpression().selectionAt(0).call(SqlFunctions.Today);
		Assert.empty(func.Arguments);
	}

	// DateTime static methods

	function testParse() {
		final func = Query.select(Book).Select(b -> Date.fromString(b.title)).ToExpression().selectionAt(0).call(SqlFunctions.Parse);
		Assert.single(func.Arguments).column("title");
	}

	function testIsLeapYear() {
		final func = Query.select(Book).Select(b -> Sql.isLeapYear(b.publishedYear)).ToExpression().selectionAt(0).call(SqlFunctions.IsLeapYear);
		Assert.single(func.Arguments).column("publishedYear");
	}

	function testDaysInMonth() {
		final func = Query.select(Book).Select(b -> Sql.daysInMonth(b.publishedYear, 1)).ToExpression().selectionAt(0).call(SqlFunctions.DaysInMonth);
		Assert.count(2, func.Arguments);
		func.Arguments[0].column("publishedYear");
		Assert.isTrue(func.Arguments[1].constant().Value.match(SqlConstInt(1)));
	}

	// DateTime constructor

	function testConstructor_YearMonthDay() {
		final func = Query.select(Book).Select(b -> Sql.dateFromParts(b.publishedYear, 1, 1)).ToExpression().selectionAt(0).call(SqlFunctions.DateTimeFromParts);
		Assert.count(3, func.Arguments);
		func.Arguments[0].column("publishedYear");
	}

	function testConstructor_YearMonthDayHourMinuteSecond() {
		final func = Query.select(Book).Select(b -> new Date(b.publishedYear, 6, 15, 12, 30, 45)).ToExpression().selectionAt(0).call(SqlFunctions.DateTimeFromParts);
		Assert.count(6, func.Arguments);
	}
}
