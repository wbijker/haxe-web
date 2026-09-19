package suites;

import codequery.Guid;
import codequery.inspection.SchemaInspector;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`ServerGuidDdlTests.cs` — server-generated Guid keys: the database fills the key via a
	per-dialect UUID default, reachable only by explicit configuration.
**/
class ServerGuidDdlTests extends TestCase {
	function testServerGuid_RendersUuidDefault_PerDialect() {
		Assert.skip("PostgresSqlDriver/MssqlSqlDriver/MySqlSqlDriver: dialect-specific UUID defaults");
	}

	function testServerGuid_OnSqlite_UsesRandomblobUuidDefault() {
		Assert.skip("SqliteSqlDriver: dialect-specific UUID default");
	}

	function testClientGuid_RendersNoDefault() {
		final def = SchemaInspector.FromType(SgClientGuid);
		final sql = new SqlTranslator().ToSql(def.ToCreateTableExpression());

		Assert.doesNotContain("gen_random_uuid", sql);
		Assert.doesNotContain("NEWSEQUENTIALID", sql);
		Assert.doesNotContain("UUID()", sql);
	}

	function testServerGuid_IsNotAutoIncrement() {
		final def = SchemaInspector.FromType(SgServerGuid);
		Assert.isFalse(def.Columns[0].IsAutoIncrement);
		Assert.isTrue(def.Columns[0].ServerGeneratedGuid);
	}
}

@tableName("t")
private class SgServerGuid {
	@columnPrimaryKey({generation: "ServerGenerated"})
	public var id:Guid;

	public function new() {}
}

@tableName("t")
private class SgClientGuid {
	public var id:Guid; // convention: client-generated

	public function new() {}
}
