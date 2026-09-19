package suites;

import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("people")
class AllPerson {
	public var id:Int = 0;
	public var name:String = "";
	public var age:Int = 0;

	public function new() {}
}

@tableName("pets")
class AllPet {
	public var id:Int = 0;
	public var ownerId:Int = 0;

	public function new() {}
}

/**
	`SelectAllColumnsTests.cs` — C# names every column a query with no projection selects; this
	port leaves the `*`, which is the one design choice the two make differently.
**/
class SelectAllColumnsTests extends TestCase {
	static final NoColumns = "SelectionExpander: this port selects * rather than naming every column";

	function testNoProjection_NamesEveryColumn() {
		Assert.skip(NoColumns);
	}

	function testTheColumnsAreTheEntitys_InItsOrder() {
		Assert.skip(NoColumns);
	}

	function testAJoinToAPlainTable_StillJoinsTheTable() {
		final select = Query.select(AllPerson)
			.InnerJoin(Query.select(AllPet), (p, pet) -> pet.ownerId == p.id)
			.ToExpression();

		// The joined query is still "just the table", so nothing has to nest it.
		final joined = select.joinedQuery();
		Assert.isTrue(joined.IsSimpleTableQuery());
		Assert.equals("pets", joined.tableSource().Table.Name);
	}

	function testExists_SelectsNothingInParticular() {
		Assert.skip("DbFunction/DbStoredProc: routines not ported");
	}
}
