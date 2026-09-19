package suites;

import codequery.inspection.SchemaInspector;
import codequery.migrations.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/**
	`UnsizedStringTests.cs` — what a string with nothing said about it becomes: the dialect's
	unbounded text, not a width nobody chose.
**/
class UnsizedStringTests extends TestCase {
	function testAStringNobodySized_CarriesNoWidth() {
		Assert.isNull(SchemaInspector.FromType(UsPlain).Columns.single(c -> c.Name == "note").MaxLength);
	}

	function testAndIsTheUnboundedTextOfWhicheverDialect() {
		Assert.skip("PostgresSqlDriver/MySqlSqlDriver/MssqlSqlDriver/SqliteSqlDriver: dialect spellings of unbounded text");
	}

	function testAWidthThatWasAskedFor_IsTheWidthTheColumnGets() {
		Assert.skip("PostgresSqlDriver: dialect spelling of VARCHAR columns");
	}

	function testTheFluentSurfaceSaysItToo_EitherWay() {
		Assert.skip("PostgresSqlDriver: dialect spelling of VARCHAR and TEXT columns");
	}

	/** A column stored as another type takes no invented width either. */
	function testAConvertedColumn_IsUnboundedUntilItIsSized() {
		final definition = SchemaInspector.FromType(UsPlain);
		new EntityTableBuilder<UsPlain>(definition)
			.Column(p -> p.id)
			.Convert((i:Int) -> Std.string(i), (s:String) -> Std.parseInt(s));

		Assert.isNull(definition.Columns.single(c -> c.Name == "id").MaxLength);
	}
}

@tableName("t")
private class UsPlain {
	public var id:Int = 0;
	public var note:String = "";

	public function new() {}
}

@tableName("t")
private class UsSized {
	public var id:Int = 0;
	@columnMaxLength(120) public var code:String = "";
	@maxLength(80) public var reference:String = "";
	@stringLength(40) public var label:String = "";

	public function new() {}
}
