package suites;

import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`InlineTimestampEndpointTests.cs` — the endpoints of a timestamp, written into a statement
	rather than bound. Haxe's `Date` has no `MinValue`/`MaxValue`, and the infinity spelling is
	PostgreSQL's; the ordinary timestamp is what this port renders.
**/
class InlineTimestampEndpointTests extends TestCase {
	static function Rendered(value:Date):String {
		return new SqlTranslator().RenderExpression(Expr.constDate(value));
	}

	function testPostgres_WritesTheEndpointsAsInfinity() {
		Assert.skip("DateTime.MinValue/MaxValue: Haxe's Date has no endpoints; '-infinity'/'infinity' is PostgresSqlDriver's spelling");
	}

	function testPostgres_LeavesAnOrdinaryTimestampAlone() {
		Assert.equals("'2026-03-01 09:30:00'", Rendered(new Date(2026, 2, 1, 9, 30, 0)));
	}

	function testPostgresOffsets_TakeTheSameEndpoints() {
		Assert.skip("DateTimeOffset: no zoned date type in this port; '-infinity'/'infinity' is PostgresSqlDriver's spelling");
	}

	function testOtherDialectsWriteThePlainLiteral() {
		Assert.skip("SqliteSqlDriver/MySqlSqlDriver/MssqlSqlDriver: no other dialects in this port; DateTime.MinValue: Haxe's Date has no endpoints");
	}
}
