package suites;

import codequery.EntityColumnNames;
import codequery.Query;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

@tableName("truck_outbound_telemetry")
class ColumnNamedTelemetry {
	@columnName("trip_number")
	public var tripNumber:String = "";

	@columnName("location_type")
	public var locationType:String = "";

	/** Named after its field, so it is the same on both sides and needs no entry. */
	public var sequence:Int = 0;

	public function new() {}
}

/**
	`ColumnNameAttributeQueryTests.cs`: `@columnName` is declarative — an entity that names its
	columns on the type needs no registration for a query to name them the same way.
**/
class ColumnNameAttributeQueryTests extends TestCase {
	function testQuery_NamesColumnsFromTheAttribute_WithoutAnyRegistration() {
		final select = Query.select(ColumnNamedTelemetry)
			.Where(t -> t.locationType == "Destination")
			.Select(t -> {tripNumber: t.tripNumber, sequence: t.sequence})
			.ToExpression();

		// The column the table is read by is the mapped one, wherever it appears.
		select.selectionOf("tripNumber").column("trip_number");
		select.whereClause().comparison("location_type", Equal, "Destination");

		// A field whose column matches its name is untouched.
		select.selectionOf("sequence").column("sequence");
	}

	function testProjection_NamesMembersByTheRowTypesOwnColumnNames() {
		// The member name comes from the type projected into, so a mapped row type carries its names
		// through — a view defined by this query creates the columns the report expects.
		final select = Query.select(ColumnNamedTelemetry)
			.Select(t -> cast({tripNumber: t.tripNumber}, ColumnNamedTelemetry))
			.ToExpression();

		select.selectionOf("trip_number").column("trip_number");
	}

	function testResolveColumn_ReadsTheAttribute_AndLeavesConventionalNamesAlone() {
		Assert.equals("trip_number", EntityColumnNames.resolveColumn(ColumnNamedTelemetry, "tripNumber"));
		Assert.equals("sequence", EntityColumnNames.resolveColumn(ColumnNamedTelemetry, "sequence"));
	}

	function testResolveProperty_MapsTheColumnBack_SoRowsMaterializeOntoTheProperty() {
		Assert.equals("tripNumber", EntityColumnNames.resolveField(ColumnNamedTelemetry, "trip_number"));
	}

	function testIsMapped_IsTrueForAnEntityThatRenamesAColumnOnTheTypeAlone() {
		Assert.isTrue(EntityColumnNames.isMapped(ColumnNamedTelemetry));
	}

	function testRegister_OverridesTheAttribute_BecauseItKnowsSomethingTheTypeCannotSay() {
		Assert.skip("EntityColumnNames.Register: runtime registration not in this port (column names are settled while compiling)");
	}
}
