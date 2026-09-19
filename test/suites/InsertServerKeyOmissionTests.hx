package suites;

import codequery.DbTable;
import codequery.InsertStrategy;
import codequery.Query;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("widgets")
class OmissionWidget {
	public var id:Int = 0;
	@columnNullable(false)
	public var name:String = "";

	public function new(id:Int = 0, name:String = "") {
		this.id = id;
		this.name = name;
	}
}

/**
	`InsertServerKeyOmissionTests.cs`: a server-generated key is omitted from the INSERT only when
	the caller left it at its default, and `PopulatePrimaryKey` governs read-back alone. Every
	test stores rows and reads them back, which nothing on the eval target can do.
**/
class InsertServerKeyOmissionTests extends TestCase {
	static final NoDatabase = "needs a database: eval has none (PHP runtime only)";

	static final widgets:DbTable<OmissionWidget> = Query.table(OmissionWidget);

	function testDefaultKey_NoPopulate_IsOmittedSoTheDatabaseGeneratesDistinctKeys() {
		Assert.skip(NoDatabase);
	}

	function testExplicitKey_NoPopulate_IsKeptAndStored() {
		Assert.skip(NoDatabase);
	}

	function testDefaultKey_WithPopulate_ReadsGeneratedKeyBackOntoTheObject() {
		Assert.skip(NoDatabase);
	}

	function testMixedBatch_KeepsExplicitKeysAndGeneratesForDefaults() {
		Assert.skip(NoDatabase);
	}

	function testPrimaryKeyGiven_StoresADefaultKeyAsItself() {
		Assert.skip(NoDatabase);
	}

	function testPrimaryKeyGiven_KeepsTheZeroRowAndTheRowThatIsOne() {
		Assert.skip(NoDatabase);
	}

	/** It is one INSERT, not the two the split into generated and explicit rows would make. */
	function testPrimaryKeyGiven_DoesNotSplitTheBatch() {
		final strategy = new InsertStrategy();
		strategy.Keys = PrimaryKey;
		strategy.ValueMode = Inline;

		final insert = widgets.InsertMany([new OmissionWidget(0, "zero"), new OmissionWidget(7, "seven")], strategy);

		// One statement, both rows, the keys as given — what can be seen without storing it.
		Assert.count(2, insert.Values);
		insert.insertValue("id", 0).value(0);
		insert.insertValue("id", 1).value(7);
		Assert.skip(NoDatabase);
	}
}
