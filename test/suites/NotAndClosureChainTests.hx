package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.notandclosurechain.Entities;

using codequery.testing.SqlAssert;

/**
	`NotAndClosureChainTests.cs` — logical negation becomes a `NOT`, a captured nullable is read for its
	value, and a lateral join over a plain table degrades to the non-lateral join it amounts to.
**/
class NotAndClosureChainTests extends TestCase {
	function testLogicalNot_NegatesTheColumn() {
		final select = Query.select(Order).Where(o -> !o.shipped).ToExpression();

		select.whereClause().not().Operand.column("shipped");
	}

	function testLogicalNot_InJoinCondition() {
		final select = Query.select(Order)
			.InnerJoin(Query.select(Customer), (o, c) -> o.customerId == c.id && !o.shipped)
			.ToExpression();

		final and = select.join().On.binary(And);
		and.Left.columnComparison("customerId", Equal, "id");
		and.Right.not().Operand.column("shipped");
	}

	/** C# reads `customerId.Value`; a `Null<Int>` is read as it stands here. */
	function testNullableClosureValue_IsReadForItsValue() {
		final customerId:Null<Int> = 42;

		final select = Query.select(Order).Where(o -> o.customerId == customerId).ToExpression();

		// The value is read at conversion, so the query carries 42 — not a "Value" column of something.
		select.whereClause().comparison("customerId", Equal, 42);
	}

	// ---- what a lateral over a plain table comes out as ------------------------------------------------

	function testInnerJoinLateral_OverPlainTable_RendersCrossJoin() {
		final sql = new SqlTranslator().ToSql(Query.select(Order)
			.InnerJoinLateral(o -> Query.select(Customer))
			.ToExpression());

		Assert.contains("CROSS JOIN Customer", sql);
		Assert.doesNotContain("LATERAL", sql);
	}

	function testLeftJoinLateral_OverPlainTable_RendersLeftJoinOnTrue() {
		final sql = new SqlTranslator().ToSql(Query.select(Order)
			.LeftJoinLateral(o -> Query.select(Customer))
			.ToExpression());

		Assert.contains("LEFT JOIN Customer", sql);
		Assert.contains("ON TRUE", sql);
		Assert.doesNotContain("LATERAL", sql);
	}
}
