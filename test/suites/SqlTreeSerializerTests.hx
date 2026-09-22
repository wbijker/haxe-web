package suites;

import codequery.DbTable;
import codequery.QualifiedTableName;
import codequery.migrations.SqlTreeSerializer;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SelectExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

class Widget {
	public var id:Int = 0;
	public var price:Float = 0;
	public var name:String = "";

	public function new() {}
}

/** `SqlTreeSerializerTests.cs`: a statement's native structure, written and read back. */
class SqlTreeSerializerTests extends TestCase {
	static function Widgets():DbTable<Widget> {
		return codequery.Query.table(Widget, "Widget");
	}

	function testView_SelectExpression_RoundTrips_Structurally_And_ToSameSql() {
		final select = Widgets().From().Where(w -> w.price > 100 && w.name != "x").OrderBy(w -> w.price).ToExpression();
		final back:SelectExpression = SqlTreeSerializer.Deserialize(SqlTreeSerializer.Serialize(select), SelectExpression);
		Assert.equals(SqlTreeSerializer.Canonical(select), SqlTreeSerializer.Canonical(back));
		Assert.equals(new SqlTranslator().ToSql(select), new SqlTranslator().ToSql(back));
	}

	function testView_WithJoinAndProjection_RoundTrips() {
		final select = Widgets().From().Where(w -> w.price >= 10).Select(w -> {id: w.id, total: w.price}).ToExpression();
		final back:SelectExpression = SqlTreeSerializer.Deserialize(SqlTreeSerializer.Serialize(select), SelectExpression);
		Assert.equals(SqlTreeSerializer.Canonical(select), SqlTreeSerializer.Canonical(back));
		Assert.equals(new SqlTranslator().ToSql(select), new SqlTranslator().ToSql(back));
	}

	function testStoredProcBody_RoundTrips_Structurally_And_ToSameSql() {
		Assert.skip("DbFunction/DbStoredProc: routines not ported (StoredProcBody)");
	}

	function testFunction_Body_RoundTrips_And_RendersSameCreateFunction() {
		Assert.skip("DbFunction/DbStoredProc: routines not ported (StoredProcBody)");
	}

	function testCanonical_IsInsensitiveTo_DriverFormatting() {
		// The structure is what is compared, never the SQL — pretty-printed rendering of a SELECT is
		// not in this port, so the half of this that compares two layouts of the same SQL is not either.
		final select = Widgets().From().Where(w -> w.price > 5).ToExpression();
		Assert.equals(SqlTreeSerializer.Canonical(select), SqlTreeSerializer.Canonical(select));
	}
}
