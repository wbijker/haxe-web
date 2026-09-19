package suites;

import codequery.DatabaseMeta;
import codequery.migrations.DatabaseColumnType;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/** `DatabaseMetaTests.cs` — DatabaseMeta exposes an entity's columns, types and primary key. */
class DatabaseMetaTests extends TestCase {
	function testGetColumns_ListsColumnsWithTypes() {
		final columns = DatabaseMeta.Default.GetColumns(MetaAuthor);

		Assert.equals(["id", "name", "bio", "age"], columns.map(c -> c.ColumnName));
		Assert.equals(DatabaseColumnType.VarChar, columns.single(c -> c.ColumnName == "name").Type);
	}

	function testGetColumns_IdentifiesPrimaryKey() {
		final columns = DatabaseMeta.Default.GetColumns(MetaAuthor);

		Assert.isTrue(columns.single(c -> c.ColumnName == "id").IsPrimaryKey);
		Assert.isFalse(columns.single(c -> c.ColumnName == "name").IsPrimaryKey);
	}

	function testGetColumns_CompositeKey_MarksBoth() {
		final pk = DatabaseMeta.Default.GetPrimaryKeyColumns(MetaEnrollment);
		Assert.equals(["studentId", "courseId"], pk);
	}

	function testGetColumns_HonoursColumnNameAttribute() {
		final column = DatabaseMeta.Default.GetColumns(MetaLabeled).single(c -> c.PropertyName == "name");
		Assert.equals("display_name", column.ColumnName);
		Assert.equals("name", column.PropertyName);
		Assert.notNull(column.Property);
	}

	function testGetColumns_IsCached() {
		final meta = new DatabaseMeta();
		Assert.isTrue(meta.GetColumns(MetaAuthor) == meta.GetColumns(MetaAuthor));
	}
}

private class MetaAuthor {
	public var id:Int = 0;
	public var name:String = "";
	public var bio:Null<String>;
	public var age:Int = 0;

	public function new() {}
}

@tableName("composite")
private class MetaEnrollment {
	@columnPrimaryKey
	public var studentId:Int = 0;

	@columnPrimaryKey
	public var courseId:Int = 0;

	public var grade:String = "";

	public function new() {}
}

private class MetaLabeled {
	public var id:Int = 0;

	@columnName("display_name")
	public var name:String = "";

	public function new() {}
}
