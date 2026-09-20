package suites;

import codequery.Guid;
import codequery.inspection.SchemaInspector;
import codequery.migrations.*;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`IdentityDdlTests.cs` — a server-generated auto-increment key renders the dialect's identity
	keyword; a client-generated (or non-auto-increment) key does not.
**/
class IdentityDdlTests extends TestCase {
	static function Ddl(def:DatabaseTableDefinition):String {
		return new SqlTranslator().ToSql(def.ToCreateTableExpression());
	}

	function testServerGeneratedIntKey_RendersIdentity_PerDialect() {
		Assert.skip("PostgresSqlDriver/MySqlSqlDriver/MssqlSqlDriver/SqliteSqlDriver: dialect-specific identity keywords");
	}

	function testClientGeneratedGuidKey_RendersNoIdentity() {
		final sql = Ddl(SchemaInspector.FromType(IdGuidKey));

		Assert.doesNotContain("IDENTITY", sql);
		Assert.doesNotContain("AUTO_INCREMENT", sql);
	}

	function testAutoIncrementOff_RendersNoIdentity() {
		final sql = Ddl(SchemaInspector.FromType(IdNoAutoInc));

		Assert.doesNotContain("IDENTITY", sql);
		Assert.doesNotContain("AUTO_INCREMENT", sql);
	}
}

@tableName("t")
private class IdIntKey {
	public var id:Int = 0;

	public function new() {}
}

@tableName("t")
private class IdGuidKey {
	public var id:Guid;

	public function new() {}
}

@tableName("t")
private class IdNoAutoInc {
	@columnPrimaryKey({autoIncrement: false})
	public var id:Int = 0;

	public function new() {}
}
