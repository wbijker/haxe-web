package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `InsertReturningMergeTests.cs`: SQL Server's MERGE + OUTPUT pattern for reading generated keys back. */
class InsertReturningMergeTests extends TestCase {
	static final Mssql = "MssqlSqlDriver: no SQL Server dialect in this port";

	function testMultiRow_UsesMergeWithPositionMarkerAndOrderedSelect() {
		Assert.skip(Mssql);
	}

	function testSingleRow_KeepsPlainOutputForm() {
		Assert.skip(Mssql);
	}

	function testNoReturning_IsAnOrdinaryInsert() {
		Assert.skip(Mssql);
	}
}
