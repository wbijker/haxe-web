package suites;

import codequery.Merge;
import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

class Account {
	public var id:Int = 0;
	public var balance:Float = 0;
	public var closed:Bool = false;

	public function new() {}
}

class Staging {
	public var id:Int = 0;
	public var balance:Float = 0;

	public function new() {}
}

/** `MergeDslTests.cs`: the strongly-typed `Merge.Into(…).Using(…).WhenMatched/NotMatched(…)` DSL. */
class MergeDslTests extends TestCase {
	function testFullUpsert_TranslatesLambdas() {
		final merge = Merge.Into(Account)
			.Using(Query.select(Staging), (t, s) -> t.id == s.id)
			.WhenMatchedUpdate((t, s) -> {balance: s.balance})
			.WhenNotMatchedInsert((t, s) -> {id: s.id, balance: s.balance})
			.Build();

		final sql = new SqlTranslator().ToSql(merge);

		Assert.contains("MERGE INTO Account AS t0", sql);
		Assert.contains("ON t0.id = t1.id", sql);
		Assert.contains("WHEN MATCHED THEN UPDATE SET balance = t1.balance", sql);
		Assert.contains("WHEN NOT MATCHED THEN INSERT (id, balance) VALUES (t1.id, t1.balance)", sql);
	}

	function testConditionalDelete_TranslatesAndClause() {
		final merge = Merge.Into(Account)
			.Using(Query.select(Staging), (t, s) -> t.id == s.id)
			.WhenMatchedDelete((t, s) -> t.closed)
			.Build();

		final sql = new SqlTranslator().ToSql(merge);
		Assert.contains("WHEN MATCHED AND t0.closed THEN DELETE", sql);
	}
}
