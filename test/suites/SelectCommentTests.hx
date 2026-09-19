package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("readings")
class SelectCommentReading {
	public var id:Int = 0;
	public var deviceId:String = "";

	public function new() {}
}

/** `SelectCommentTests.cs` — `WithComments`: a comment above the statement and one below it. */
class SelectCommentTests extends TestCase {
	static function sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	function testTheCommentsSitAroundTheStatement() {
		final rendered = sql(Query.select(SelectCommentReading)
			.Where(r -> r.deviceId == "dev-a")
			.WithComments("latest reading per device — DeviceReport.Load", "end DeviceReport.Load")
			.ToExpression());

		Assert.equals(
			"-- latest reading per device — DeviceReport.Load\n"
			+ "SELECT * FROM readings AS t0 WHERE t0.deviceId = 'dev-a'\n"
			+ "-- end DeviceReport.Load",
			rendered);
	}

	function testOneOrTheOther() {
		Assert.startsWith("-- above\nSELECT", sql(Query.select(SelectCommentReading).WithComments("above").ToExpression()));

		Assert.endsWith("\n-- below", sql(Query.select(SelectCommentReading).WithComments(null, "below").ToExpression()));
	}

	function testEachLineIsCommented() {
		final rendered = sql(Query.select(SelectCommentReading).WithComments("first\nsecond").ToExpression());

		Assert.startsWith("-- first\n-- second\nSELECT", rendered);
	}

	function testTheQueryIsOtherwiseUnchanged() {
		final plain = sql(Query.select(SelectCommentReading)
			.Where(r -> r.id > 0).OrderByDesc(r -> r.id).Limit(5)
			.ToExpression());

		final commented = sql(Query.select(SelectCommentReading)
			.Where(r -> r.id > 0).OrderByDesc(r -> r.id).Limit(5)
			.WithComments("note")
			.ToExpression());

		Assert.equals("-- note\n" + plain, commented);
	}

	function testTheQueryCarriesOn() {
		final expression = Query.select(SelectCommentReading)
			.WithComments("note")
			.Where(r -> r.id > 0)
			.ToExpression();

		expression.whereClause().comparison("id", GreaterThan, 0);
		Assert.equals("note", expression.CommentAbove);
	}

	function testTheExpressionSaysSo() {
		final expression = Query.select(SelectCommentReading).WithComments("above", "below").ToExpression();

		Assert.equals("above", expression.CommentAbove);
		Assert.equals("below", expression.CommentBelow);
	}
}
