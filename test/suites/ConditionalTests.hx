package suites;

import codequery.Query;
import codequery.queries.ISelectQuery;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.conditional.Entities;

using codequery.testing.SqlAssert;

/**
	`ConditionalTests.cs` — `Conditional`: a clause only sometimes wanted, said in the middle of the
	chain instead of taking the chain apart into a variable and an `if`.
**/
class ConditionalTests extends TestCase {
	static function sql(query:ISelectQuery<Booking>):String {
		return new SqlTranslator().ToSql(query.ToExpression());
	}

	/** The whole point: the same SQL as the if, to the character. */
	function testItIsTheIfStatement() {
		for (condition in [true, false]) {
			final chained = Query.select(Booking)
				.Conditional(condition, q -> q.Where(b -> b.status == Status.Confirmed));

			var written = Query.select(Booking);
			if (condition) {
				written = written.Where(b -> b.status == Status.Confirmed);
			}

			Assert.equals(sql(written), sql(chained));
		}
	}

	function testWhenItHolds_TheClauseIsThere() {
		final rendered = sql(Query.select(Booking).Conditional(true, q -> q.Where(b -> b.id > 7)));

		Assert.contains("WHERE", rendered);
		Assert.contains("> 7", rendered);
	}

	function testWhenItDoesNot_TheQueryIsUntouched() {
		final rendered = sql(Query.select(Booking).Conditional(false, q -> q.Where(b -> b.id > 7)));

		Assert.doesNotContain("WHERE", rendered);
	}

	/** The lambda is not read at all when the condition does not hold. */
	function testWhenItDoesNot_TheLambdaIsNotRun() {
		var ran = false;

		Query.select(Booking).Conditional(false, q -> {
			ran = true;
			return q;
		});

		Assert.isFalse(ran);
	}

	function testTheyChain() {
		final rendered = sql(Query.select(Booking)
			.Conditional(true, q -> q.Where(b -> b.id > 7))
			.Conditional(false, q -> q.Where(b -> b.status == Status.Pending))
			.Conditional(true, q -> q.OrderByDesc(b -> b.checkIn)));

		Assert.contains("> 7", rendered);
		Assert.doesNotContain("Pending", rendered);
		Assert.contains("ORDER BY", rendered);
		Assert.doesNotContain("= 0", rendered);
	}

	function testTheOtherwiseOverloadPicksOne() {
		final newest = sql(Query.select(Booking)
			.Conditional(true, q -> q.OrderByDesc(b -> b.checkIn), q -> q.OrderBy(b -> b.checkIn)));
		final oldest = sql(Query.select(Booking)
			.Conditional(false, q -> q.OrderByDesc(b -> b.checkIn), q -> q.OrderBy(b -> b.checkIn)));

		Assert.contains("DESC", newest);
		Assert.doesNotContain("DESC", oldest);
	}

	function testAnUpdateTakesOneToo() {
		final update = Query.table(Booking).Update()
			.Set(b -> b.status, Status.Confirmed)
			.Conditional(true, q -> q.Where(b -> b.id > 7));

		Assert.contains("> 7", new SqlTranslator().ToSql(update.ToExpression()));
	}

	function testAndADelete() {
		final delete = Query.table(Booking).Delete().Conditional(true, q -> q.Where(b -> b.id > 7));

		Assert.contains("> 7", new SqlTranslator().ToSql(delete.ToExpression()));
	}

	function testALambdaThatIsNotThere_SaysSo() {
		Assert.throws(() -> Query.select(Booking).Conditional(true, null));
	}
}
