package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/**
	`EnumColumnTypeTests.cs` — an enum abstract over Int is an integer column, and its members render
	as the number the database stores.
**/
class EnumColumnTypeTests extends TestCase {
	function testEnumColumn_HasIntType() {
		final exp = Query.select(Doc).Select(d -> d.status).ToExpression();
		Assert.equals(SqlType.SqlInt, exp.selectionAt(0).column().ColumnType);
	}

	function testEnumConstant_RendersUnderlyingValue() {
		final sql = new SqlTranslator().ToSql(
			Query.select(Doc).Where(d -> d.status == Status.Active).ToExpression());
		// An enum abstract is its underlying Int already, so the column needs no CAST as C#'s enum
		// does; the constant renders as 1.
		Assert.contains("t0.status = 1", sql);
	}
}

enum abstract Status(Int) {
	final Draft = 0;
	final Active = 1;
	final Archived = 2;
}

class Doc {
	public var id:Int = 0;
	public var status:Status = Draft;

	public function new() {}
}
