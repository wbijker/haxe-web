package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("parts")
class Part {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

/**
	`CallFunctionTests.cs` — `Sql.call`, C#'s `DbFunctions.Call`: a function the library has no word
	for, because it belongs to an extension, a dialect, or the caller. The name is a string;
	everything around it is not.
**/
class CallFunctionTests extends TestCase {
	static function AssertCall(e:ISqlExpression, name:String):SqlCallExpression {
		final call = Assert.isType(e, SqlCallExpression);
		Assert.equals(name, call.Name);
		return call;
	}

	/** The case it exists for: pg_trgm's similarity, which nothing here names. */
	function testItCallsAFunctionTheLibraryDoesNotName() {
		final term = "bolt";

		final call = AssertCall(Query.select(Part).Select(p -> (Sql.call("word_similarity", p.name, term) : Float)).ToExpression().selectionAt(0),
			"word_similarity");

		Assert.count(2, call.Arguments);
		call.Arguments[0].column("name");
		call.Arguments[1].value("bolt");
	}

	/** The arguments are expressions, so a column is still a column and a value still a value. */
	function testTheArgumentsAreStillExpressions() {
		final call = AssertCall(Query.select(Part).Select(p -> (Sql.call("my_fn", p.id, p.id + 1, "x") : Int)).ToExpression().selectionAt(0), "my_fn");

		Assert.count(3, call.Arguments);
		call.Arguments[0].column("id");
		call.Arguments[1].comparison("id", Add, 1);
		call.Arguments[2].value("x");
	}

	function testItTakesNoArgumentsAtAll() {
		Assert.empty(AssertCall(Query.select(Part).Select(p -> (Sql.call("gen_random_uuid") : String)).ToExpression().selectionAt(0),
			"gen_random_uuid").Arguments);
	}

	function testItCanBeSchemaQualified() {
		final call = AssertCall(Query.select(Part).Select(p -> (Sql.call("ext.similarity", p.name) : Float)).ToExpression().selectionAt(0),
			"ext.similarity");

		Assert.single(call.Arguments).column("name");
	}

	/** It orders and filters like anything else, which is what the ranked search needed. */
	function testItOrdersAndFilters() {
		final select = Query.select(Part)
			.Where(p -> (Sql.call("word_similarity", p.name, "bolt") : Float) > 0.3)
			.OrderByDesc(p -> (Sql.call("word_similarity", p.name, "bolt") : Float))
			.Select(p -> {id: p.id})
			.ToExpression();

		final comparison = select.whereBinary(GreaterThan);
		AssertCall(comparison.Left, "word_similarity").Arguments[0].column("name");
		comparison.Right.value(0.3);

		Assert.isFalse(select.orderBy().Ascending);
		AssertCall(select.orderBy().Expression, "word_similarity");
	}

	/**
		It names a function and nothing else. A name carrying anything a function name cannot carry is
		refused — which is the difference between an escape hatch and a way to write SQL by hand.
	**/
	function testANameThatIsNotAFunctionNameIsRefused() {
		final injected = Assert.throwsMessage(() -> Query.select(Part).Select(p -> (Sql.call("f(1); DROP TABLE parts; --", p.id) : Int)).ToExpression());
		Assert.contains("is not a function name", injected);

		Assert.throws(() -> Query.select(Part).Select(p -> (Sql.call("f\"x", p.id) : Int)).ToExpression());
		Assert.throws(() -> Query.select(Part).Select(p -> (Sql.call("1abc", p.id) : Int)).ToExpression());
		Assert.throws(() -> Query.select(Part).Select(p -> (Sql.call("", p.id) : Int)).ToExpression());
		Assert.throws(() -> Query.select(Part).Select(p -> (Sql.call("a b", p.id) : Int)).ToExpression());
		Assert.throws(() -> Query.select(Part).Select(p -> (Sql.call("f()", p.id) : Int)).ToExpression());
	}

	/** The name is written at the call site, so what reaches the database is a name. */
	function testANameThatIsNotWrittenThereIsRefused() {
		Assert.skip("Sql.call with a name held in a variable is refused while compiling, which a test cannot catch");
	}
}
