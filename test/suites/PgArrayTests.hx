package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `PgArrayTests.cs`. `PgArray<T>` is the PostgreSQL array column type, which the port does not have. */
class PgArrayTests extends TestCase {
	static inline final Reason = "PgArray: PostgreSQL array type not ported";

	function testInspection_MapsPgArrayToExtensionColumnWithArrayTypeName() {
		Assert.skip(Reason);
	}

	function testCreateTable_RendersPostgresArrayTypes() {
		Assert.skip(Reason);
	}

	function testPgArray_IsNotDroppedAsANavigationProperty() {
		Assert.skip(Reason);
	}
}
