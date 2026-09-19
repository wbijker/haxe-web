package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.correlatedsubquery.Entities;

using codequery.testing.SqlAssert;

/** `CorrelatedSubqueryTests.cs`. */
class CorrelatedSubqueryTests extends TestCase {
	static function sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	function testWhereExists_Correlated_GivesTheInnerSourceItsOwnAlias() {
		final select = Query.select(Customer)
			.WhereExists(Query.table(Order, "Order"), (c, o) -> o.customerId == c.id)
			.ToExpression();

		Assert.equals("Customer", select.selectTableName());

		final exists = select.whereClause().exists();
		Assert.equals("Order", exists.Subquery.selectTableName());

		final correlation = exists.Subquery.whereClause().binary(Equal);
		correlation.Left.column("customerId");
		correlation.Right.column("id");

		// The inner source is a source of its own, so the correlation has two aliases to name.
		Assert.equals("SELECT * FROM Customer AS t0 WHERE EXISTS (SELECT * FROM Order AS t1 WHERE t1.customerId = t0.id)",
			sql(select));
	}

	function testWhereNotExists_Correlated_NegatesTheExists() {
		final select = Query.select(Customer)
			.WhereNotExists(Query.table(Order, "Order"), (c, o) -> o.customerId == c.id)
			.ToExpression();

		final exists = select.whereClause().exists(true);

		final correlation = exists.Subquery.whereClause().binary(Equal);
		correlation.Left.column("customerId");
		correlation.Right.column("id");
		Assert.contains("NOT EXISTS (SELECT * FROM Order AS t1 WHERE t1.customerId = t0.id)", sql(select));
	}

	function testWhereExists_CorrelationCanIncludeInnerFilters() {
		final select = Query.select(Customer)
			.WhereExists(Query.table(Order, "Order"), (c, o) -> o.customerId == c.id && o.total > 100)
			.ToExpression();

		final subquery = select.whereClause().exists().Subquery;
		final and = subquery.whereBinary(And);

		final correlation = and.Left.binary(Equal);
		correlation.Left.column("customerId");
		correlation.Right.column("id");

		and.Right.comparison("total", GreaterThan, 100);
		Assert.contains("WHERE t1.customerId = t0.id AND t1.total > 100", sql(select));
	}

	function testWhereExists_CombinesWithOuterPredicates() {
		final select = Query.select(Customer)
			.Where(c -> c.name != "")
			.WhereExists(Query.table(Order, "Order"), (c, o) -> o.customerId == c.id)
			.ToExpression();

		final and = select.whereBinary(And);

		// Name is a nullable column, so `!= ""` answers as the language does — a null name is a different name.
		final distinct = and.Left.distinctFrom();
		distinct.Left.column("name");
		distinct.Right.value("");

		and.Right.exists();
	}
}
