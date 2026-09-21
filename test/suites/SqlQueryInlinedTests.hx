package suites;

import codequery.execution.SqlQuery;
import codequery.sqlexpressions.SqlConstValue;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `SqlQuery.Inlined` — the values written into the statement where its placeholders were, for a log. */
class SqlQueryInlinedTests extends TestCase {
	static function positional(sql:String, values:Array<SqlConstValue>):String {
		return new SqlQuery({Sql: sql, Parameters: values}, _ -> "?").Inlined();
	}

	static function numbered(sql:String, values:Array<SqlConstValue>):String {
		return new SqlQuery({Sql: sql, Parameters: values}, n -> '$$$n').Inlined();
	}

	function testPositionalPlaceholdersTakeTheValuesInOrder() {
		Assert.equals("SELECT * FROM t WHERE a = 1 AND b = 'x'",
			positional("SELECT * FROM t WHERE a = ? AND b = ?", [SqlConstInt(1), SqlConstString("x")]));
	}

	function testNumberedPlaceholdersTakeTheirOwnValue() {
		Assert.equals("SELECT 'b', 'a', 'b'",
			numbered("SELECT $2, $1, $2", [SqlConstString("a"), SqlConstString("b")]));
	}

	function testTheTwelfthIsNotTheFirstAndATwo() {
		final values = [for (i in 1...13) SqlConstInt(i)];
		Assert.equals("SELECT 12, 1", numbered("SELECT $12, $1", values));
	}

	function testAQuestionMarkInsideAStringIsNotAPlaceholder() {
		Assert.equals("SELECT 'why?' WHERE a = 1", positional("SELECT 'why?' WHERE a = ?", [SqlConstInt(1)]));
	}

	function testEachKindOfValueIsWrittenAsSqlDoes() {
		Assert.equals("TRUE, 2.5, 'it''s', '2026-03-09 00:00:00', NULL",
			positional("?, ?, ?, ?, ?", [SqlConstBool(true), SqlConstFloat(2.5), SqlConstString("it's"),
				SqlConstDate(new Date(2026, 2, 9, 0, 0, 0)), SqlConstNull]));
	}

	function testNoValuesLeavesTheStatementAlone() {
		Assert.equals("SELECT ?", positional("SELECT ?", []));
	}
}
