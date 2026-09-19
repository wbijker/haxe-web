package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.closurecall.Entities;

using StringTools;
using codequery.testing.SqlAssert;

/**
	`ClosureCallTests.cs` — a call in a lambda that reads nothing of the row is not a question for the
	database: it is a value the query already has, so it is called while the query is built and
	travels as data.
**/
class ClosureCallTests extends TestCase {
	static function normalize(value:String):String {
		return value.trim().toLowerCase();
	}

	static function startOfDay(day:Date):Date {
		return new Date(day.getFullYear(), day.getMonth(), day.getDate(), 0, 0, 0);
	}

	function testAHelperOverCapturedValuesIsCalled() {
		final term = "  BOLT ";

		// The helper ran while the query was built, so what the query carries is its answer.
		Query.select(Part).Where(p -> p.name == normalize(term)).Select(p -> {id: p.id}).ToExpression()
			.whereClause().comparison("name", Equal, "bolt");
	}

	function testSoIsOneReturningADate() {
		final day = new Date(2024, 2, 4, 17, 30, 0);

		Query.select(Part).Where(p -> p.created >= startOfDay(day)).Select(p -> {id: p.id}).ToExpression()
			.whereClause().comparison("created", GreaterThanOrEqual, new Date(2024, 2, 4, 0, 0, 0));
	}

	/** An instance method on a captured value counts too — that is all a closure is. */
	function testAndAnInstanceMethodOnACapturedValue() {
		final prefix = "BO";

		Query.select(Part).Where(p -> p.name == prefix.toLowerCase()).Select(p -> {id: p.id}).ToExpression()
			.whereClause().comparison("name", Equal, "bo");
	}

	function testAHelperThatReadsTheRowSaysWhy() {
		Assert.skip("CodeQueryTranslateException at build time: the port converts while compiling, so a helper "
			+ "called over the row is a compile error, not an exception a test can catch");
	}
}
