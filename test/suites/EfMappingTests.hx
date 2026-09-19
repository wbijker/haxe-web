package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `EfMappingTests.cs`. */
class EfMappingTests extends TestCase {
	static final Reason = "EntityFramework: not ported";

	function testARenamedColumn_IsQueriedByItsColumnName() {
		Assert.skip(Reason);
	}

	function testARenamedColumn_IsRegisteredForEveryStatementToResolve() {
		Assert.skip(Reason);
	}

	function testARenamedColumn_IsStillReportedForInspection() {
		Assert.skip(Reason);
	}

	function testASchemaQualifiedTable_IsQueriedInItsSchema() {
		Assert.skip(Reason);
	}

	function testASchemaQualifiedTable_IsStillReportedForInspection() {
		Assert.skip(Reason);
	}

	function testOnSqlite_TheSchemaIsDropped_AsEfDropsIt() {
		Assert.skip(Reason);
	}
}
