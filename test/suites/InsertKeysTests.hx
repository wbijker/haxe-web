package suites;

import codequery.BulkStrategy;
import codequery.DbTable;
import codequery.InsertStrategy;
import codequery.Query;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("widgets")
class KeyedWidget {
	public var id:Int = 0;
	@columnNullable(false)
	public var name:String = "";

	public function new(id:Int = 0, name:String = "") {
		this.id = id;
		this.name = name;
	}
}

/** A key the client makes — a Guid in C#, which here is a string: neither is counted by a sequence. */
@tableName("tokens")
class Token {
	@columnPrimaryKey
	public var id:String = "";
	@columnNullable(false)
	public var name:String = "";

	public function new() {}
}

/**
	`InsertKeysTests.cs`: where an insert's keys come from, and what the sequence is told about it
	afterwards. `PrimaryKey` stores the keys the rows carry; `PrimaryKeyResync` stores them and moves
	the table's key generator past the highest of them.
**/
class InsertKeysTests extends TestCase {
	static final widgets:DbTable<KeyedWidget> = Query.table(KeyedWidget);
	static final tokens:DbTable<Token> = Query.table(Token);

	static function Keys(keys:InsertKeys):InsertStrategy {
		final strategy = new InsertStrategy();
		strategy.Keys = keys;
		return strategy;
	}

	function testPrimaryKeyResync_StoresTheKeysAsGiven_AndLeavesTheNextOneClear() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testPrimaryKeyResync_SetsTheSequenceToTheHighestKeyInTheList() {
		final statement = widgets.ResyncStatement(
			[new KeyedWidget(7), new KeyedWidget(4000), new KeyedWidget(12)], Keys(PrimaryKeyResync));

		Assert.equals("SELECT setval(pg_get_serial_sequence('widgets', 'id'), 4000)", statement);
	}

	function testTheOtherTwoOwesTheSequenceNothing() {
		final rows = [new KeyedWidget(7)];

		Assert.isNull(widgets.ResyncStatement(rows, new InsertStrategy()));
		Assert.isNull(widgets.ResyncStatement(rows, Keys(PrimaryKey)));
	}

	function testPrimaryKeyResync_OnAGuidKey_IsRefusedByName() {
		final token = new Token();
		token.id = "3f2504e0-4f89-11d3-9a0c-0305e82c3301";
		token.name = "t";

		final message = Assert.throwsMessage(() -> tokens.Insert(token, Keys(PrimaryKeyResync)));

		Assert.contains("Token.id", message);
		Assert.contains("sequence", message);
	}

	/**
		A bulk load is where borrowed keys usually arrive, and it owes the sequence the same thing an
		ordinary insert does — `BulkStrategy` is an `InsertStrategy` that has chosen the copy protocol.
	**/
	function testABulkLoad_OwesTheSequenceTheSameResync() {
		final strategy = new BulkStrategy();
		strategy.Keys = PrimaryKeyResync;

		final statement = widgets.ResyncStatement([new KeyedWidget(12), new KeyedWidget(4000)], strategy);

		Assert.equals("SELECT setval(pg_get_serial_sequence('widgets', 'id'), 4000)", statement);
	}

	function testSettingASequenceOnAnotherDialectsTable_IsRefusedBeforeAnythingIsSent() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port to refuse a sequence");
	}
}
