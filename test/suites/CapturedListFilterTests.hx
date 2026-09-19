package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.capturedlistfilter.Entities;

using codequery.testing.SqlAssert;

/**
	`CapturedListFilterTests.cs` — the optional filter: `list == null || list.contains(c)`, which is how
	a read says "narrow by these, or don't narrow at all". Both halves are answered while the query is
	built, because both are about a value the query holds rather than anything in the database.
**/
class CapturedListFilterTests extends TestCase {
	/** With a list, the guard is false and what remains is the filter. */
	function testAListNarrowsTheQuery() {
		var ids:Array<Int> = [1, 2, 3];

		final membership = Query.select(Part).Where(p -> ids == null || ids.contains(p.id)).Select(p -> {id: p.id})
			.ToExpression().whereClause().inValues([1, 2, 3]);
		membership.Value.column("id");
	}

	/** Without one the guard is true, and the filter is never converted. */
	function testNoListLeavesTheQueryUnnarrowed() {
		var ids:Array<Int> = null;

		Query.select(Part).Where(p -> ids == null || ids.contains(p.id)).Select(p -> {id: p.id})
			.ToExpression().whereClause().constant(true);
	}

	/** A captured collection has no SQL form at all, so a test against one is answered here. */
	function testACapturedCollectionIsNeverRendered() {
		var ids:Array<Int> = [1];

		// Nothing of the guard survives: what is left is the membership test, over the values themselves.
		final membership = Query.select(Part).Where(p -> ids == null || ids.contains(p.id)).Select(p -> {id: p.id})
			.ToExpression().whereClause().inValues([1]);
		for (value in membership.Values) {
			Assert.isTrue(Std.isOfType(value.valueOf(), Int));
		}
	}

	/** The other way round, and negated, mean what they say. */
	function testTheGuardReadsBothWays() {
		var ids:Array<Int> = [7];
		var none:Array<Int> = null;

		Query.select(Part).Where(p -> null == ids || ids.contains(p.id)).Select(p -> {id: p.id})
			.ToExpression().whereClause().inValues([7]).Value.column("id");
		Query.select(Part).Where(p -> ids != null && ids.contains(p.id)).Select(p -> {id: p.id})
			.ToExpression().whereClause().inValues([7]).Value.column("id");
		Query.select(Part).Where(p -> none != null && none.contains(p.id)).Select(p -> {id: p.id})
			.ToExpression().whereClause().constant(false);
	}

	/** An AND with a decided side keeps the other, so a guard in front of a real filter narrows to exactly that filter. */
	function testADecidedSideLeavesTheOther() {
		final apply = true;

		Query.select(Part).Where(p -> apply && p.name == "bolt").Select(p -> {id: p.id})
			.ToExpression().whereClause().comparison("name", Equal, "bolt");
		Query.select(Part).Where(p -> !apply || p.name == "bolt").Select(p -> {id: p.id})
			.ToExpression().whereClause().comparison("name", Equal, "bolt");
	}

	/** A column tested against null is a question for the database and stays one. */
	function testAColumnKeepsItsNullTest() {
		final isNull = Query.select(Part).Where(p -> p.name == null).Select(p -> {id: p.id})
			.ToExpression().whereClause().binary(Equal);
		isNull.Left.column("name");
		isNull.Right.nullConst();

		final isNotNull = Query.select(Part).Where(p -> p.name != null).Select(p -> {id: p.id})
			.ToExpression().whereClause().binary(NotEqual);
		isNotNull.Left.column("name");
		isNotNull.Right.nullConst();
	}

	/** A captured scalar keeps its test too: the database can hold one, so the query says what the caller wrote. */
	function testACapturedScalarKeepsItsNullTest() {
		var maybe:Null<Int> = null;

		final or = Query.select(Part).Where(p -> maybe == null || p.id == maybe).Select(p -> {id: p.id})
			.ToExpression().whereClause().binary(Or);

		final guard = or.Left.binary(Equal);
		guard.Left.nullConst();
		guard.Right.nullConst();
	}
}
