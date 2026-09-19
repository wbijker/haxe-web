package suites;

import codequery.QualifiedTableName;
import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

class NamedReading {
	public var id:Int = 0;
	public var value:Float = 0;

	public function new() {}
}

/**
	`SqlFunctionNamingTests.cs` — a function is named by a string, so the set is open. What core
	defines in `SqlFunctions` is a concept every dialect should be able to spell; anything else is
	the caller naming a database function directly, which needs no translation and gets none.
**/
class SqlFunctionNamingTests extends TestCase {
	static function Pg(selection:ISqlExpression):String {
		final expression = Query.select(NamedReading).ToExpression();
		expression.Selection = selection;
		return new SqlTranslator().ToSql(expression);
	}

	function testAFunctionCoreNeverHeardOf_RendersAsAPlainCall() {
		final call = new SqlFunctionExpression("time_bucket", [Expr.constString("1 hour"), Expr.constInt(5)]);

		Assert.contains("time_bucket('1 hour', 5)", Pg(call));
	}

	function testAFunctionCoreDefined_ButTheDialectCannotSpell_IsRefused() {
		// JsonExtract is a core name — every dialect is expected to have some spelling, and one that
		// has none says so rather than emitting JSONEXTRACT(...) and failing at the database. C# asks
		// the routine renderer; routines are not in this port, so the statement translator is asked.
		final jsonExtract = new SqlFunctionExpression(SqlFunctions.JsonExtract, [Expr.paramString("doc"), Expr.paramString("path")]);

		final error = Assert.throwsMessage(() -> Pg(jsonExtract));

		Assert.contains("JsonExtract", error);
	}

	function testThatSameUnknownName_AlsoWorksInsideARoutineBody() {
		// The routine renderers are not in this port; the expression renders the same on its own.
		final call = new SqlFunctionExpression("uuid_generate_v4", []);

		Assert.equals("uuid_generate_v4()", new SqlTranslator().RenderExpression(call));
	}

	function testTheNamesCoreDefines_AreItsOwnConstants() {
		Assert.isTrue(SqlFunctions.IsKnown(SqlFunctions.AddHours));
		Assert.isTrue(SqlFunctions.IsKnown("Upper"));
		Assert.isFalse(SqlFunctions.IsKnown("time_bucket"));

		// The constant's value is its name, so a tree built before this change reads the same.
		Assert.equals("AddHours", SqlFunctions.AddHours);
	}

	function testAnExtensionsFunction_IsTheSameNodeAsAnyOther() {
		// PostGIS and the full-text helpers used to need a node of their own; the name being a string
		// is all that distinguished them.
		final sites = new TableSqlSource(new QualifiedTableName("sites"), "t0");
		final distance = new SqlFunctionExpression("ST_Distance", [
			new ColumnSqlExpression(sites, "Location", SqlUnknown),
			new ColumnSqlExpression(sites, "Origin", SqlUnknown)
		]);

		Assert.contains("ST_Distance(t0.Location, t0.Origin)", Pg(distance));
	}
}
