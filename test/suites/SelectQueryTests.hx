package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.*;

using codequery.testing.SqlAssert;

/** `SelectQueryTests.cs`. */
class SelectQueryTests extends TestCase {
	function testLimitAndOffset_AreClausesOfTheStatement() {
		final select = Query.select(Book).OrderBy(b -> b.id).Limit(10).Offset(20).ToExpression();
		Assert.equals(10, select.Limit);
		Assert.equals(20, select.Offset);
		select.orderBy().Expression.column("id");
	}

	function testLimitAndOffset_RenderSqlServerOffsetFetch() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testInnerJoin_AcceptsTableDirectly() {
		final select = Query.select(Book)
			.InnerJoin(Query.table(Author, "authors"), (b, a) -> b.authorId == a.id)
			.ToExpression();
		final join = select.joinOfType(Inner);
		Assert.equals("authors", join.Source.tableName());
		join.On.columnComparison("authorId", Equal, "id");
	}

	function testInnerJoin_KeyBased_BuildsEqualityCondition() {
		Assert.skip("InnerJoin(table, outerKey, innerKey): key-based join overload not in this port");
	}

	function testWhere_AccumulatesWithAnd() {
		final select = Query.select(Book).Where(b -> b.id > 1).Where(b -> b.authorId == 2).ToExpression();
		final and = select.whereBinary(And);
		and.Left.comparison("id", GreaterThan, 1);
		and.Right.comparison("authorId", Equal, 2);
	}

	function testToSql_RendersASimpleSelect() {
		final sql = new SqlTranslator().ToSql(Query.select(Book).Where(b -> b.id == 1).ToExpression());
		Assert.equals("SELECT * FROM Book AS t0 WHERE t0.id = 1", sql);
	}
}
