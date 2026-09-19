package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("book")
class ConcurrentBook {
	public var id:Int = 0;
	public var title:String = "";

	public function new() {}
}

/**
	`ConcurrentRenderTests.cs` — one driver, many renders. C# renders them in parallel; the eval
	target has one thread, so they are rendered one after another and each is checked to have come
	back with its own parameters and its own SQL.
**/
class ConcurrentRenderTests extends TestCase {
	static final Renders = 200;

	function testManyRendersAtOnce_EachKeepsItsOwnParameters() {
		final driver = new SqlTranslator();
		final wrong = [];

		for (i in 0...Renders) {
			final id = i;
			final query = Query.select(ConcurrentBook).Where(b -> b.id == id).ToExpression();

			driver.ToSql(query);
			final parameters = driver.Parameters;
			final value = parameters.length == 1 ? SqlAssert.ValueOfConst(parameters[0]) : null;

			if (parameters.length != 1 || value != id) {
				wrong.push('render $id came back with ${parameters.length} parameter(s), value $value');
			}
		}

		Assert.empty(wrong);
	}

	function testManyRendersAtOnce_EachKeepsItsOwnSql() {
		final driver = new SqlTranslator();
		final wrong = [];

		for (i in 0...Renders) {
			final title = 'book $i';
			final id = i;
			final query = Query.select(ConcurrentBook).Where(b -> b.id == id && b.title == title).ToExpression();

			final sql = driver.ToSql(query);

			if (sql != "SELECT * FROM book AS t0 WHERE t0.id = $1 AND t0.title = $2") {
				wrong.push(sql);
			}
		}

		Assert.empty(wrong);
	}

	function testAForkKeepsTheDialectsSettings() {
		Assert.skip("ISqlTranslator.Fork: not in this port (a render keeps its state on the translator it was asked of)");
	}

	function testADriverIsSafeToShare() {
		Assert.skip("ISqlTranslator.Fork: not in this port (a render keeps its state on the translator it was asked of)");
	}
}
