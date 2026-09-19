package suites;

import codequery.migrations.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

class FkAuthor {
	public var id:Int = 0;

	public function new() {}
}

class FkBook {
	public var id:Int = 0;
	@:foreignKey(FkAuthor) public var authorId:Int = 0;
	@:foreignKey(FkAuthor, index = false) public var editorId:Int = 0;

	public function new() {}
}

/** The FK column is the primary key here, so it's already covered — no extra index. */
class OwnedProfile {
	@:primaryKey @:foreignKey(FkAuthor) public var authorId:Int = 0;

	public function new() {}
}

/** `ForeignKeyIndexTests.cs`: foreign-key columns are indexed by default; opt out with `index = false`. */
class ForeignKeyIndexTests extends TestCase {
	function testForeignKey_IsIndexedByDefault() {
		final indexes = SchemaInspector.FromType(FkBook).Indexes;
		Assert.isTrue(Lambda.exists(indexes, i -> i.Name == "IX_FkBook_authorId" && i.Columns.length == 1 && i.Columns[0].ColumnName == "authorId"));
	}

	function testForeignKey_IndexFalse_IsNotIndexed() {
		final indexes = SchemaInspector.FromType(FkBook).Indexes;
		Assert.isFalse(Lambda.exists(indexes, i -> Lambda.exists(i.Columns, c -> c.ColumnName == "editorId")));
	}

	function testForeignKey_CoveredByPrimaryKey_IsNotDuplicated() {
		final indexes = SchemaInspector.FromType(OwnedProfile).Indexes;
		Assert.isFalse(Lambda.exists(indexes, i -> Lambda.exists(i.Columns, c -> c.ColumnName == "authorId")));
	}
}
