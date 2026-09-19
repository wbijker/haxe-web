package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/**
	`SelectOperationGapTests.cs`: DISTINCT, INTERSECT / EXCEPT (alongside UNION / UNION ALL), and
	CROSS JOIN (alongside the other joins).
**/
class SelectOperationGapTests extends TestCase {
	// --- DISTINCT ---

	function testDistinct_MarksTheStatementDistinct() {
		final select = Query.select(Book).Distinct().ToExpression();

		Assert.isTrue(select.IsDistinct);
	}

	function testDistinct_AfterProjection() {
		final select = Query.select(Book).Select(b -> {authorId: b.authorId}).Distinct().ToExpression();

		// Distinct after a projection dedupes the rows the projection produced, and says so on the
		// projection itself: DISTINCT names no columns, so it means the same thing written into the
		// statement as wrapped around it — and one statement is what it renders as.
		Assert.isTrue(select.IsDistinct);
		Assert.equals(["authorId"], select.memberNames());
	}

	function testDistinct_WithWhere() {
		final select = Query.select(Book).Where(b -> b.publishedYear > 2000).Distinct().ToExpression();

		Assert.isTrue(select.IsDistinct);
		select.whereClause().comparison("publishedYear", GreaterThan, 2000);
	}

	// --- INTERSECT / EXCEPT ---

	function testIntersect_AddsAnIntersectMember() {
		final a = Query.select(Book).Where(b -> b.publishedYear > 2000).Select(b -> {id: b.id});
		final b = Query.select(Book).Where(x -> x.authorId == 1).Select(x -> {id: x.id});

		final select = a.Intersect(b).ToExpression();

		final member = select.union();
		Assert.equals(SetOperationType.Intersect, member.Type);
		member.Query.whereClause().comparison("authorId", Equal, 1);
	}

	function testExcept_AddsAnExceptMember() {
		final a = Query.select(Book).Select(b -> {id: b.id});
		final b = Query.select(Book).Where(x -> x.authorId == 1).Select(x -> {id: x.id});

		final select = a.Except(b).ToExpression();

		Assert.equals(SetOperationType.Except, select.union().Type);
	}

	function testExcept_KeepsTheMembersInOrder() {
		final a = Query.select(Book).Where(b -> b.publishedYear > 2000).Select(b -> {id: b.id});
		final b = Query.select(Book).Where(x -> x.publishedYear <= 2000).Select(x -> {id: x.id});

		final select = a.Except(b).ToExpression();

		// EXCEPT is not commutative: the statement it was called on is the one rows are taken from.
		select.whereClause().comparison("publishedYear", GreaterThan, 2000);

		final subtracted = select.union();
		Assert.equals(SetOperationType.Except, subtracted.Type);
		subtracted.Query.whereClause().comparison("publishedYear", LessThanOrEqual, 2000);
	}

	// --- CROSS JOIN ---

	function testCrossJoin_HasNothingToJoinOn() {
		final select = Query.select(Book).CrossJoin(Query.select(Author)).ToExpression();

		final join = select.joinOfType(Cross);
		Assert.equals("Author", join.Source.tableName());
		Assert.isNull(join.On);
	}

	function testCrossJoin_RendersOnAllDialects() {
		// The C# renders on PostgreSQL, SQL Server and SQLite; the port has one dialect, and it must
		// say CROSS JOIN rather than anything like CROSS APPLY.
		final q = Query.select(Book).CrossJoin(Query.select(Author));
		final expr = q.ToExpression();

		Assert.contains("CROSS JOIN", new SqlTranslator().ToSql(expr));
	}

	function testCrossJoin_ThenSelectAcrossBothSources() {
		final select = Query.select(Book)
			.CrossJoin(Query.select(Author))
			.Select((b, a) -> {title: b.title, name: a.name})
			.ToExpression();

		final author = select.joinOfType(Cross).Source;

		select.columnIn(select.selectionOf("title"), "title", select.Source.Alias);
		select.columnIn(select.selectionOf("name"), "name", author.Alias);
	}

	function testCrossJoin_ChainsToThirdSource() {
		final select = Query.select(Book)
			.CrossJoin(Query.select(Author))
			.CrossJoin(Query.select(AuthorGroup))
			.ToExpression();

		Assert.count(2, select.Joins);
		Assert.equals("Author", select.joinOfType(Cross, 0).Source.tableName());
		Assert.equals("AuthorGroup", select.joinOfType(Cross, 1).Source.tableName());
	}
}
