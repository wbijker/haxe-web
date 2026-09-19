package suites;

import codequery.Decimal;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`GeneratedColumnTests.cs` — generated/computed columns emitted as part of the CREATE TABLE DDL
	per driver, and migrated. Every expectation here is a dialect's own spelling, or a plan the
	migration planner makes, neither of which this port has.
**/
class GeneratedColumnTests extends TestCase {
	function testPostgres_StoredOnly() {
		Assert.skip("PostgresSqlDriver: dialect-specific generated-column DDL");
	}

	function testPostgres_VirtualThrows() {
		Assert.skip("PostgresSqlDriver: dialect-specific generated-column DDL");
	}

	function testMySql_StoredAndVirtual() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testSqlite_StoredAndVirtual() {
		Assert.skip("SqliteSqlDriver: dialect-specific generated-column DDL");
	}

	function testSqlServer_ComputedAndPersisted() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testTernary_RendersCase() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testChangedGeneratedExpression_IsAlteredInPlace_WithSetExpression() {
		Assert.skip("MigrationPlanner: migration planner not ported");
	}

	function testChangedGeneratedExpression_PrePostgres17_FallsBackToDropAndReadd() {
		Assert.skip("MigrationPlanner: migration planner not ported");
	}

	function testChangedGeneratedExpression_MySql_AltersWithModifyColumn() {
		Assert.skip("MigrationPlanner: migration planner not ported");
	}

	function testChangedGeneratedExpression_SqlServer_ReDeclaresComputedColumn() {
		Assert.skip("MigrationPlanner: migration planner not ported");
	}

	function testPlainColumnBecomingGenerated_IsDroppedAndReAdded() {
		Assert.skip("MigrationPlanner: migration planner not ported");
	}

	function testDbGenerated_IsInspectedAndRendered() {
		Assert.skip("DbGenerated<T>: generated-column property type not ported");
	}
}

private class GcBook {
	public var id:Int = 0;
	public var price:Decimal = 0;
	public var pageCount:Int = 0;
	public var pricePerPage:Decimal = 0;

	public function new() {}
}
