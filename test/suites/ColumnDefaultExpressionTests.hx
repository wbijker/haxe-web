package suites;

import codequery.Sql;
import codequery.inspection.SchemaInspector;
import codequery.migrations.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.Linq;

/**
	`ColumnDefaultExpressionTests.cs` — a column's DEFAULT written as the value it is, with the
	snapshot recording the standard's own spelling.
**/
class ColumnDefaultExpressionTests extends TestCase {
	static function Builder():EntityTableBuilder<CdDelivery> {
		final snapshot = new SchemaSnapshot();
		final definition = SchemaInspector.FromType(CdDelivery);
		snapshot.Tables.push(definition);
		snapshot.Bind(CdDelivery, definition);
		return snapshot.Entity(CdDelivery);
	}

	static function Column(t:EntityTableBuilder<CdDelivery>, name:String):DatabaseColumnDefinition {
		return t.Definition.Columns.single(c -> c.Name == name);
	}

	function testNow_IsRenderedByEachDialectInItsOwnSpelling() {
		Assert.skip("PostgresSqlDriver/MssqlSqlDriver/MySqlSqlDriver/SqliteSqlDriver: dialect spellings of NOW()");
	}

	function testNow_IsStoredInTheSnapshotAsTheStandardSpelling() {
		final t = Builder();
		t.Column(c -> c.createdTimestamp).Default(() -> Sql.now());

		// The snapshot is what the next migration diffs against, so it belongs to no dialect.
		Assert.equals("CURRENT_TIMESTAMP", Column(t, "createdTimestamp").DefaultValue);
	}

	function testUtcNow_DoesNotCollapseOntoNow() {
		final now = Builder();
		now.Column(c -> c.createdTimestamp).Default(() -> Sql.now());

		final utc = Builder();
		utc.Column(c -> c.createdTimestamp).Default(() -> Sql.utcNow());

		Assert.notEqual(Column(now, "createdTimestamp").DefaultValue, Column(utc, "createdTimestamp").DefaultValue);
	}

	function testAnEnumDefault_TakesItsUnderlyingValue() {
		final t = Builder();
		t.Column(c -> c.status).Default(() -> CdDeliveryStatus.Pending);

		Assert.equals("1", Column(t, "status").DefaultValue);
	}

	function testAPlainValue_IsNotBracketed_EvenWhereExpressionsAre() {
		Assert.skip("MySqlSqlDriver/SqliteSqlDriver: dialect spellings of DEFAULT");
	}

	function testAStringDefault_IsQuotedAsAValue() {
		final t = Builder();
		t.Column(c -> c.reference).Default(() -> "");

		Assert.equals("''", Column(t, "reference").DefaultValue);
	}
}

private enum abstract CdDeliveryStatus(Int) {
	var Pending = 1;
	var Sent = 2;
}

@tableName("delivery")
private class CdDelivery {
	public var id:Int = 0;
	public var createdTimestamp:Date;
	public var status:CdDeliveryStatus;
	public var retries:Int = 0;
	public var reference:String = "";

	public function new() {}
}
