package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.nullableinequality.Entities;

using codequery.testing.SqlAssert;

/**
	`NullableInequalityTests.cs` — `!=` against a column that can hold NULL. The language calls a null
	row different; SQL calls the comparison unknown and drops the row. The lambda is the language, so
	it answers as the language does.
**/
class NullableInequalityTests extends TestCase {
	function testANullableColumnAnswersAsCSharpDoes() {
		final distinct = Query.select(Ticket).Where(t -> t.assigneeId != 7).Select(t -> {id: t.id}).ToExpression()
			.subquery().whereClause().distinctFrom();

		distinct.Left.column("assigneeId");
		distinct.Right.value(7);
		Assert.isFalse(Std.isOfType(distinct.Left, RowSqlExpression));
	}

	/** A string is nullable unless the schema says otherwise — the same rule the migration uses. */
	function testSoDoesAStringColumn() {
		final distinct = Query.select(Ticket).Where(t -> t.note != "x").Select(t -> {id: t.id}).ToExpression()
			.subquery().whereClause().distinctFrom();

		distinct.Left.column("note");
		distinct.Right.value("x");
	}

	/** A column that cannot be NULL has nothing to disagree about, and stays plain. */
	function testAColumnThatCannotBeNullStaysPlain() {
		Query.select(Ticket).Where(t -> t.title != "x").Select(t -> {id: t.id}).ToExpression()
			.subquery().whereClause().comparison("title", NotEqual, "x");
		Query.select(Ticket).Where(t -> t.priority != 3).Select(t -> {id: t.id}).ToExpression()
			.subquery().whereClause().comparison("priority", NotEqual, 3);
	}

	/** `==` already agrees with the language: neither keeps a NULL row. */
	function testEqualityIsUnchanged() {
		Query.select(Ticket).Where(t -> t.assigneeId == 7).Select(t -> {id: t.id}).ToExpression()
			.subquery().whereClause().comparison("assigneeId", Equal, 7);
	}

	/** A test against null is a question about null, and already reads right. */
	function testANullTestIsStillANullTest() {
		final comparison = Query.select(Ticket).Where(t -> t.assigneeId != null).Select(t -> {id: t.id}).ToExpression()
			.subquery().whereClause().binary(NotEqual);

		comparison.Left.column("assigneeId");
		comparison.Right.nullConst();
	}

	/** Two nullable columns compared to each other: distinct is what the language means there too. */
	function testTwoNullableColumns() {
		final distinct = Query.select(Ticket).Where(t -> t.note != t.title).Select(t -> {id: t.id}).ToExpression()
			.subquery().whereClause().distinctFrom();

		distinct.Left.column("note");
		distinct.Right.column("title");
	}

	function testTheOtherDialectsSayTheSameThing() {
		Assert.skip("MssqlSqlDriver/MySqlSqlDriver/SqliteSqlDriver: other dialects' spellings of IS DISTINCT FROM");
	}

	function testAnUnassignedTicketIsNotAssignedToSeven() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
