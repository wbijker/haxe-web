package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("readings")
class CommentReading {
	public var id:Int = 0;
	public var value:Float = 0;
	public var deviceId:String = "";

	public function new() {}
}

/** `SqlCommentTests.cs` — `SqlComment.Create`, here `Sql.comment`: something said about a value, in the SQL, beside it. */
class SqlCommentTests extends TestCase {
	static function sql(statement:ISqlStatement):String {
		return new SqlTranslator().ToSql(statement);
	}

	// ---- in a projection -------------------------------------------------------------------------------

	function testItFollowsTheProjectedColumn() {
		final rendered = sql(Query.select(CommentReading)
			.Select(r -> {column1: Sql.comment(r.value * 2, "Multiple value by 2"), deviceId: r.deviceId})
			.ToExpression());

		Assert.equals(
			"SELECT t0.value * 2 AS column1 /* Multiple value by 2 */, t0.deviceId AS deviceId FROM readings AS t0",
			rendered);
	}

	function testAProjectionOfOneReadsTheSame() {
		Assert.equals(
			"SELECT t0.value * 2 AS doubled /* twice the reading */ FROM readings AS t0",
			sql(Query.select(CommentReading)
				.Select(r -> {doubled: Sql.comment(r.value * 2, "twice the reading")})
				.ToExpression()));
	}

	// ---- anywhere else an expression goes ---------------------------------------------------------------

	function testItSitsBesideAValueInAPredicate() {
		final rendered = sql(Query.select(CommentReading)
			.Where(r -> Sql.comment(r.value, "the raw reading") > 0)
			.Select(r -> {id: r.id})
			.ToExpression());

		Assert.contains("WHERE t0.value /* the raw reading */ > 0", rendered);
	}

	function testTheValueIsUnchanged() {
		final plain = sql(Query.select(CommentReading)
			.Where(r -> r.value > 0).Select(r -> {id: r.id}).ToExpression());

		final commented = sql(Query.select(CommentReading)
			.Where(r -> Sql.comment(r.value, "note") > 0).Select(r -> {id: r.id}).ToExpression());

		Assert.equals(plain, StringTools.replace(commented, " /* note */", ""));
	}

	// ---- every dialect ---------------------------------------------------------------------------------

	function testEveryDialectWritesIt() {
		// A block comment is spelled the same everywhere; this port has the one dialect to spell it in.
		final rendered = sql(Query.select(CommentReading)
			.Select(r -> {doubled: Sql.comment(r.value * 2, "twice")})
			.ToExpression());

		Assert.contains("/* twice */", rendered);
		Assert.endsWith("/* twice */ FROM " + sql(Query.select(CommentReading).ToExpression()).split("FROM ")[1], rendered);
	}

	// ---- in a routine body -----------------------------------------------------------------------------

	function testItWorksInsideARoutineBody() {
		Assert.skip("DbFunction/DbStoredProc: routines not ported");
	}

	// ---- what it refuses to let through ----------------------------------------------------------------

	function testTextThatWouldEndTheCommentEarlyIsDefused() {
		final rendered = sql(Query.select(CommentReading)
			.Select(r -> {x: Sql.comment(r.value, "ends early */ SELECT 1")})
			.ToExpression());

		Assert.contains("/* ends early * / SELECT 1 */", rendered);
		Assert.doesNotContain("*/ SELECT 1", rendered);
	}

	function testItIsAlwaysOneLine() {
		final rendered = sql(Query.select(CommentReading)
			.Select(r -> {x: Sql.comment(r.value, "first\nsecond")})
			.ToExpression());

		Assert.contains("/* first second */", rendered);
	}

	function testTheExpressionIsStillThere() {
		final expression = Query.select(CommentReading)
			.Select(r -> {x: Sql.comment(r.value, "note")})
			.ToExpression();

		final comment = Assert.isType(expression.selectionOf("x"), SqlCommentExpression);

		Assert.equals("note", comment.Text);
		comment.Value.column("value");
	}
}
