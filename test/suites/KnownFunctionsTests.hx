package suites;

import codequery.Query;
import codequery.Sql;
import codequery.SqlDate;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using StringTools;
using codequery.testing.SqlAssert;

class KnownRow {
	public var id:Int = 0;
	public var name:String = "";
	public var value:Float = 0;
	public var when:SqlDate;

	public function new() {}
}

/**
	`KnownFunctionsTests.cs` — the built-in string/date/Math/cast translations, each family locked in
	as rendering correctly.
**/
class KnownFunctionsTests extends TestCase {
	static function Pg(select:SelectExpression):String {
		return new SqlTranslator().ToSql(select);
	}

	function testString_Functions_Translate() {
		Assert.contains("UPPER(t0.name)", Pg(Query.select(KnownRow).Select(r -> r.name.toUpperCase()).ToExpression()));
		Assert.contains("(t0.name LIKE '%a%')", Pg(Query.select(KnownRow).Select(r -> r.name.contains("a")).ToExpression()));
	}

	function testMath_Functions_Translate() {
		Assert.contains("ABS(t0.value)", Pg(Query.select(KnownRow).Select(r -> Math.abs(r.value)).ToExpression()));
		Assert.contains("ROUND(t0.value, 2)", Pg(Query.select(KnownRow).Select(r -> Sql.round(r.value, 2)).ToExpression()));
		Assert.contains("POWER(t0.value, 2)", Pg(Query.select(KnownRow).Select(r -> Math.pow(r.value, 2)).ToExpression()));
	}

	function testDateTime_Functions_Translate() {
		Assert.contains("INTERVAL", Pg(Query.select(KnownRow).Select(r -> r.when.addDays(1)).ToExpression()));
	}

	function testConvert_Functions_Translate() {
		Assert.contains("CAST(t0.value AS INTEGER)", Pg(Query.select(KnownRow).Select(r -> Std.int(r.value)).ToExpression()));
	}

	function testUnknownMethod_OfKnownType_FallsThrough_AndThrows() {
		Assert.skip("a method the converter refuses is a compile error here, which a test cannot catch");
	}
}
