package suites;

import codequery.DbTable;
import codequery.InsertStrategy;
import codequery.Query;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** Two columns marked as the key, which one read-back cannot tell apart. */
@tableName("combo")
class Combo {
	@columnPrimaryKey
	public var a:Int = 0;
	@columnPrimaryKey
	public var b:Int = 0;

	public function new() {}
}

/**
	`InsertKeyStrategyTests.cs`: runtime key strategies beyond the basic int-identity case — the
	composite-key guard, and the read-back paths that need a database.
**/
class InsertKeyStrategyTests extends TestCase {
	static final NoDatabase = "needs a database: eval has none (PHP runtime only)";

	static final combos:DbTable<Combo> = Query.table(Combo);

	function testLongKey_MultiRow_KeysAssignedInOrder_AndCoercedToLong() {
		Assert.skip(NoDatabase);
	}

	function testPerRowReadBack_RollsBackWholeBatch_OnMidBatchFailure() {
		Assert.skip("Transaction: not ported; " + NoDatabase);
	}

	function testCompositeKey_WithPopulate_ThrowsClearly() {
		final combo = new Combo();
		combo.a = 1;
		combo.b = 2;
		final populate = new InsertStrategy();
		populate.PopulatePrimaryKey = true;

		final message = Assert.throwsMessage(() -> combos.Insert(combo, populate));

		Assert.contains("composite", message.toLowerCase());
	}

	function testFluentClientGenerated_MakesInsertKeepExplicitKey_NoReadBack() {
		Assert.skip("SchemaSnapshot.Entity().Column().PrimaryKey(ValueGeneration): fluent key configuration not ported; " + NoDatabase);
	}
}
