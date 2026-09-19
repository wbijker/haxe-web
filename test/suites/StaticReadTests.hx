package suites;

import codequery.Query;
import codequery.queries.ISelectQuery;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`StaticReadTests.cs` — a lambda may read anything that is not the row — a static, a const, a
	member of a static — and what it reads is a value, worked out here and sent as one. Only a read
	of the row is a column.
**/
class StaticReadTests extends TestCase {
	static function sql(query:ISelectQuery<Currency>):String {
		return new SqlTranslator().ToSql(query.ToExpression());
	}

	function testAStaticsMemberIsAValue() {
		final rendered = sql(Query.select(Currency).Where(c -> c.id == Seed.zar.id));

		Assert.contains("id = 710", rendered);
		Assert.doesNotContain("zar", rendered);
	}

	function testAConstIsAValue() {
		Assert.contains("id = 840", sql(Query.select(Currency).Where(c -> c.id == Seed.fallback)));
	}

	function testANestedStaticIsAValue() {
		Assert.contains("id = 50", sql(Query.select(Currency).Where(c -> c.id == ConfigDefaults.pageSize)));
	}

	function testTheRowIsStillAColumn() {
		final rendered = sql(Query.select(Currency).Where(c -> c.id > 0 && c.code == "ZAR"));

		Assert.contains("id > 0", rendered);
		Assert.contains("code = 'ZAR'", rendered);
	}

	function testACapturedLocalIsAValue() {
		final id = 999;
		Assert.contains("id = 999", sql(Query.select(Currency).Where(c -> c.id == id)));
	}
}

@tableName("currency")
class Currency {
	public var id:Int = 0;
	public var code:String = "";

	public function new() {}
}

class Seed {
	public static final zar:Currency = {
		final made = new Currency();
		made.id = 710;
		made.code = "ZAR";
		made;
	};

	public static inline final fallback = 840;
}

class ConfigDefaults {
	public static var pageSize(get, never):Int;

	static function get_pageSize():Int {
		return 50;
	}
}
