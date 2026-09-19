package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.isnullpredicate.Entities;

/** `IsNullPredicateTests.cs` — null comparisons render as `IS [NOT] NULL`; `= NULL` never matches in SQL. */
class IsNullPredicateTests extends TestCase {
	function testEqualsNull_RendersIsNull() {
		final sql = new SqlTranslator().ToSql(
			Query.select(Ticket).Where(t -> t.assigneeId == null).ToExpression());

		Assert.contains("assigneeId IS NULL", sql);
		Assert.doesNotContain("= NULL", sql);
	}

	function testNotEqualsNull_RendersIsNotNull() {
		final sql = new SqlTranslator().ToSql(
			Query.select(Ticket).Where(t -> t.closedDate != null).ToExpression());

		Assert.contains("closedDate IS NOT NULL", sql);
	}

	function testNullableLiftCast_EmitsNoSqlCast() {
		// (t.id : Null<Int>) only lifts the value to its nullable counterpart — no CAST in SQL.
		final sql = new SqlTranslator().ToSql(
			Query.select(Ticket).Where(t -> (t.id : Null<Int>) == null).ToExpression());

		Assert.contains("id IS NULL", sql);
		Assert.doesNotContain("CAST", sql);
	}
}
