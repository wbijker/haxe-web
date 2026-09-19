package suites;

import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.TableConstraint;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `CreateTableIfNotExistsTests.cs`: CREATE TABLE IF NOT EXISTS rendering. */
class CreateTableIfNotExistsTests extends TestCase {
	static function Table(ifNotExists:Bool):CreateTableExpression {
		return new CreateTableExpression("__CodeQueryMigrations", [new ColumnDefinition("Id", SqlText, false, null, 256)],
			[new PrimaryKeyConstraint(["Id"])], null, ifNotExists);
	}

	function testSqlServer_GuardsWithObjectId_NotCreateTableIfNotExists() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_WithoutIfNotExists_IsAPlainCreate() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testPostgres_UsesIfNotExists() {
		final sql = new SqlTranslator().ToSql(Table(true));
		Assert.contains("CREATE TABLE IF NOT EXISTS __CodeQueryMigrations", sql);
	}
}
