package suites;

import codequery.DbTable;
import codequery.Query;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("entries")
class Entry {
	public var id:Int = 0;
	public var message:String = "";

	/**
		The older name for `message`, kept for callers that still say it. C# marks the shim
		`[NotMapped]`; here a property with accessors is not a column to begin with.
	**/
	public var subject(get, set):Null<String>;

	function get_subject():Null<String> {
		return message;
	}

	function set_subject(value:Null<String>):Null<String> {
		message = value == null ? "" : value;
		return value;
	}

	public function new() {}
}

/**
	`InsertNotMappedTests.cs`: a shim property never becomes a column, on the write side too. C#
	proves it by storing and fetching; the statement says the same thing before it is sent.
**/
class InsertNotMappedTests extends TestCase {
	static final entries:DbTable<Entry> = Query.table(Entry);

	/** The insert names only the stored column — before the fix it also named "subject". */
	function testAnInsertDoesNotNameANotMappedProperty() {
		final entry = new Entry();
		entry.id = 1;
		entry.message = "stored";

		final insert = entries.Insert(entry);

		Assert.equals(["id", "message"], insert.insertColumns());
		insert.insertValue("message").value("stored");
	}

	/** Written through the shim, the value still lands in the column the shim stands for. */
	function testWritingThroughTheShimStoresTheColumnItStandsFor() {
		final entry = new Entry();
		entry.id = 2;
		entry.subject = "said the old way";

		final insert = entries.Insert(entry);

		Assert.doesNotContain("subject", insert.insertColumns().join(","));
		insert.insertValue("message").value("said the old way");
	}
}
