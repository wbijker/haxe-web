package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.scalarsubquery.Entities;

using codequery.testing.SqlAssert;

/**
	`ScalarSubqueryTests.cs` — `DbQuery.Correlated` is `Sql.correlated`, `DbFunctions.Scalar` is
	`Sql.scalar`. A projected query is read as it stands: `ToExpression` folds the wrapper `Select` puts round it, as C#'s does, so
	query wrapped around its projection.
**/
class ScalarSubqueryTests extends TestCase {
	static function sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	/**
		The subquery's WHERE matches its own `customerId` against the outer statement's `id` — the
		correlation, and the reason the subquery cannot simply be run on its own. The aliases are
		read off the rendered statement, which is where they are given.
	**/
	static function assertCorrelatedToOuterId(subquery:SelectExpression, rendered:String) {
		final on = subquery.whereClause().binary(Equal);
		on.Left.column("customerId");
		on.Right.column("id");
		Assert.contains("WHERE t1.customerId = t0.id", rendered);
	}

	// ---- correlated -----------------------------------------------------------------------------------

	function testAnAggregateOverTheOuterRow() {
		final select = Query.select(Customer)
			.Select(c -> {
				name: c.name,
				total: Sql.correlated(Query.select(Order)
					.Where(o -> o.customerId == c.id)
					.SelectAggregation(a -> a.sum(o -> o.total))),
			})
			.ToExpression();

		final statement = select;
		Assert.equals("Customer", statement.selectTableName());
		statement.selectionOf("name").column("name");

		final subquery = statement.selectionOf("total").scalar();
		Assert.equals("Order", subquery.selectTableName());
		subquery.selectionAt(0).aggregate(Sum).Argument.column("total");
		assertCorrelatedToOuterId(subquery, sql(select));
	}

	function testACountOverTheOuterRow() {
		final select = Query.select(Customer)
			.Select(c -> {orders: Sql.correlated(Query.select(Order)
				.Where(o -> o.customerId == c.id)
				.SelectAggregation(a -> a.count()))})
			.ToExpression();

		final subquery = select.selectionOf("orders").scalar();
		Assert.isNull(subquery.selectionAt(0).aggregate(Count).Argument);
		assertCorrelatedToOuterId(subquery, sql(select));
	}

	function testALookupOfTheLatestRow() {
		final select = Query.select(Customer)
			.Select(c -> {latest: Sql.correlated(Query.select(Order)
				.Where(o -> o.customerId == c.id)
				.OrderByDesc(o -> o.id)
				.Limit(1)
				.Select(o -> o.total))})
			.ToExpression();

		final subquery = select.selectionOf("latest").scalar();
		subquery.selectionAt(0).column("total");
		assertCorrelatedToOuterId(subquery, sql(select));

		subquery.orderBy().Expression.column("id");
		Assert.isFalse(subquery.orderBy().Ascending);
		Assert.equals(1, subquery.Limit);
	}

	function testInAPredicate() {
		final select = Query.select(Customer)
			.Where(c -> Sql.correlated(Query.select(Order)
				.Where(o -> o.customerId == c.id)
				.SelectAggregation(a -> a.max(o -> o.total))) > 100)
			.Select(c -> {name: c.name})
			.ToExpression();

		final comparison = select.whereBinary(GreaterThan);
		comparison.Right.value(100);

		final subquery = comparison.Left.scalar();
		subquery.selectionAt(0).aggregate(Max).Argument.column("total");
		assertCorrelatedToOuterId(subquery, sql(select));
	}

	/** Stating the type says which is wanted where the compiler cannot see it; it is the same subquery either way. */
	function testValueSaysTheSameThingAsTheConversion() {
		final converted = Query.select(Customer)
			.Select(c -> {biggest: Sql.correlated(Query.select(Order)
				.Where(o -> o.customerId == c.id).SelectAggregation(a -> a.max(o -> o.total)))})
			.ToExpression();

		final named = Query.select(Customer)
			.Select(c -> {biggest: (Sql.correlated(Query.select(Order)
				.Where(o -> o.customerId == c.id).SelectAggregation(a -> a.max(o -> o.total))) : Float)})
			.ToExpression();

		for (select in [converted, named]) {
			final subquery = select.selectionOf("biggest").scalar();
			subquery.selectionAt(0).aggregate(Max).Argument.column("total");
			assertCorrelatedToOuterId(subquery, sql(select));
		}
	}

	function testTheOuterRowIsAColumnAndNotAValue() {
		final select = Query.select(Customer)
			.Select(c -> {n: Sql.correlated(Query.select(Order)
				.Where(o -> o.customerId == c.id).SelectAggregation(a -> a.count()))})
			.ToExpression();

		final on = select.selectionOf("n").scalar().whereClause().binary(Equal);

		// A column of the outer statement, not the 0 a default-valued stand-in would have carried.
		on.Right.column("id");
		Assert.contains("(SELECT COUNT(*) FROM Order AS t1 WHERE t1.customerId = t0.id) AS n FROM Customer AS t0", sql(select));
	}

	function testNamingNoOuterRowIsJustASubquery() {
		final select = Query.select(Customer)
			.Select(c -> {biggest: (Sql.correlated(Query.select(Order)
				.SelectAggregation(a -> a.max(o -> o.total))) : Float)})
			.ToExpression();

		final subquery = select.selectionOf("biggest").scalar();
		Assert.equals("Order", subquery.selectTableName());
		subquery.selectionAt(0).aggregate(Max).Argument.column("total");
		Assert.isNull(subquery.Where);
	}

	function testItCorrelatesToTheRowItNames_NotTheFirstSource() {
		final select = Query.select(Customer)
			.InnerJoin(Query.select(Job), (c, j) -> j.customerId == c.id)
			.InnerJoin(Query.select(Job), (c, j, pj) -> pj.customerId == c.id)
			.Select((c, j, pj) -> {
				id: c.id,
				blocked: Sql.correlated(Query.select(Line)
					.Where(l -> l.jobId == pj.id)
					.SelectAggregation(a -> a.count())),
			})
			.ToExpression();

		final subquery = select.selectionOf("blocked").scalar();
		final on = subquery.whereClause().binary(Equal);

		// pj is the second join, so the subquery reads that source — not the statement's own, and not the first join.
		on.Left.column("jobId");
		on.Right.column("id");
		final rendered = sql(select);
		Assert.contains("(SELECT COUNT(*) FROM Line AS t3 WHERE t3.jobId = t2.id) AS blocked", rendered);
		Assert.contains("INNER JOIN Job AS t2 ON t2.customerId = t0.id", rendered);
	}

	// ---- self-contained -------------------------------------------------------------------------------

	function testAScalarSubqueryWithNoOuterRow() {
		final select = Query.select(Customer)
			.Where(c -> c.id > Sql.scalar(Query.select(Order).SelectAggregation(a -> a.max(o -> o.total))))
			.Select(c -> {name: c.name})
			.ToExpression();

		final comparison = select.whereBinary(GreaterThan);

		// C# widens the int column with a CAST to meet the decimal the subquery yields; there is no
		// decimal here, and an Int compares with a Float as it stands.
		comparison.Left.column("id");

		final subquery = comparison.Right.scalar();
		Assert.equals("Order", subquery.selectTableName());
		subquery.selectionAt(0).aggregate(Max).Argument.column("total");
		Assert.isNull(subquery.Where);
	}
}
