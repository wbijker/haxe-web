package suites;

import codequery.Query;
import codequery.sqldrivers.PrettySqlTranslator;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("Row")
class PrettyRow {
	public var id:Int = 0;
	public var name:String = "";

	public function new() {}
}

/** `PrettyPrintTests.cs` — `ToSql(expression, pretty: true)`; here `PrettySqlTranslator`. */
class PrettyPrintTests extends TestCase {
	static function query():SelectExpression {
		return Query.select(PrettyRow).Where(r -> r.id > 0).ToExpression();
	}

	function testDefault_IsCompact_SingleLine() {
		final sql = new SqlTranslator().ToSql(query());
		Assert.doesNotContain("\n", sql);
		Assert.equals("SELECT * FROM Row AS t0 WHERE t0.id > 0", sql);
	}

	function testToSql_Pretty_AddsNewlines() {
		final sql = new PrettySqlTranslator().ToSql(query());
		Assert.equals("SELECT\n    *\nFROM Row AS t0\nWHERE t0.id > 0", sql);
	}

	function testToSql_Pretty_IsPerCall_DriverHasNoPersistentState() {
		// C# asks the one driver for both; here the layout is a translator of its own, and the plain
		// one is unchanged by the pretty one having rendered.
		final pretty = new PrettySqlTranslator().ToSql(query());
		final compact = new SqlTranslator().ToSql(query());

		Assert.contains("\n", pretty);
		Assert.doesNotContain("\n", compact);
	}
}
