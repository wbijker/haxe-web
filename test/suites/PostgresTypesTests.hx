package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`PostgresTypesTests.cs`.

	`PgInterval`, `PgInet`, `PgCidr`, `PgMacAddr`, `PgHStore`, `PgRange<T>` and CLR arrays are
	PostgreSQL-native column types contributed by `PostgresTypesExtension`; the port's `SqlType` has
	none of them, and no schema inspector to read them off an entity.
**/
class PostgresTypesTests extends TestCase {
	static inline final Reason = "PostgresTypesExtension: PostgreSQL-native column types not ported";

	function testInterval_RendersIntervalType() {
		Assert.skip(Reason);
	}

	function testInet_RendersInetType() {
		Assert.skip(Reason);
	}

	function testCidr_Nullable_RendersCidrType() {
		Assert.skip(Reason);
	}

	function testMacAddr_RendersMacaddrType() {
		Assert.skip(Reason);
	}

	function testHStore_RendersHstoreType() {
		Assert.skip(Reason);
	}

	function testIntArray_RendersIntegerArray() {
		Assert.skip(Reason);
	}

	function testStringArray_RendersTextArray() {
		Assert.skip(Reason);
	}

	function testGuidArray_Nullable_RendersUuidArray() {
		Assert.skip(Reason);
	}

	function testByteArray_StaysBytea_NotAnArrayType() {
		Assert.skip(Reason);
	}

	function testIntRange_RendersInt4Range() {
		Assert.skip(Reason);
	}

	function testLongRange_RendersInt8Range() {
		Assert.skip(Reason);
	}

	function testDecimalRange_RendersNumRange() {
		Assert.skip(Reason);
	}

	function testDateTimeRange_RendersTsRange() {
		Assert.skip(Reason);
	}

	function testDateTimeOffsetRange_Nullable_RendersTstzRange() {
		Assert.skip(Reason);
	}

	function testDateRange_RendersDateRange() {
		Assert.skip(Reason);
	}

	function testPgRange_ToString_RendersLiteral() {
		Assert.skip(Reason);
	}

	function testTypes_SnapshotAsExtensionColumns() {
		Assert.skip(Reason);
	}
}
