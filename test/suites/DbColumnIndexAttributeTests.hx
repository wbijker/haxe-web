package suites;

import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

@tableName("guest")
class IndexedGuest {
	public var id:Int = 0;
	// Nothing said but "index it": the name comes from the table and the column.
	@:index public var sku:String = "";
	@:index("UQ_guest_email", unique = true) public var email:String = "";
	// A composite is held together by its name, and put in order by order.
	@:index("IX_guest_country_joined", order = 0) public var country:String = "";
	@:index("IX_guest_country_joined", order = 1, descending = true) public var joinedAt:Date;

	public function new() {}
}

@tableName("booking")
class IndexedBooking {
	public var id:Int = 0;
	// Repeatable: the same column read on its own and as the head of a composite.
	@:index @:index("IX_booking_unit_check_in", order = 0) public var unitId:Int = 0;
	@:index("IX_booking_unit_check_in", order = 1) public var checkIn:Date;
	// The older spelling, on the same entity, meaning the same thing — one spelling here.
	@:index("IX_booking_status") public var status:Int = 0;

	public function new() {}
}

/** `DbColumnIndexAttributeTests.cs`: indexes declared with `@:index` — named or auto-named, unique, descending, composite. */
class DbColumnIndexAttributeTests extends TestCase {
	static function IndexSql(definition:DatabaseTableDefinition):Array<String> {
		return [for (e in definition.Diff(null)) if (Std.isOfType(e, CreateIndexExpression)) new SqlTranslator().ToSql(e)];
	}

	function testSingleColumn_AutoNamed() {
		Assert.isTrue(IndexSql(SchemaInspector.FromType(IndexedGuest)).indexOf("CREATE INDEX IX_guest_sku ON guest (sku)") >= 0);
	}

	function testNamed_Unique() {
		Assert.isTrue(IndexSql(SchemaInspector.FromType(IndexedGuest)).indexOf("CREATE UNIQUE INDEX UQ_guest_email ON guest (email)") >= 0);
	}

	function testComposite_OrderedWithDirection() {
		Assert.isTrue(IndexSql(SchemaInspector.FromType(IndexedGuest))
			.indexOf("CREATE INDEX IX_guest_country_joined ON guest (country, joinedAt DESC)") >= 0);
	}

	function testRepeatable_ColumnSitsInTwoIndexes() {
		final sql = IndexSql(SchemaInspector.FromType(IndexedBooking));
		Assert.isTrue(sql.indexOf("CREATE INDEX IX_booking_unitId ON booking (unitId)") >= 0);
		Assert.isTrue(sql.indexOf("CREATE INDEX IX_booking_unit_check_in ON booking (unitId, checkIn)") >= 0);
	}

	function testStandsAlongsideTheIndexSpelling() {
		Assert.isTrue(IndexSql(SchemaInspector.FromType(IndexedBooking)).indexOf("CREATE INDEX IX_booking_status ON booking (status)") >= 0);
	}
}
