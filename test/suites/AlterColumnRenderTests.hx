package suites;

import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `AlterColumnRenderTests.cs`: ALTER COLUMN renders type, nullability and default changes. */
class AlterColumnRenderTests extends TestCase {
	static function Alter(newNullable:Bool, newDefault:Null<ISqlExpression>, oldNullable:Bool):AlterColumnExpression {
		return new AlterColumnExpression("widgets", "score", new ColumnDefinition("score", SqlInt, newNullable, newDefault),
			new ColumnDefinition("score", SqlInt, oldNullable));
	}

	function testPostgres_SetNotNull_AndDefault() {
		final sql = new SqlTranslator().ToSql(Alter(false, new ConstSqlExpression(SqlConstInt(0)), true));
		Assert.contains("ALTER COLUMN score TYPE INTEGER", sql);
		Assert.contains("ALTER COLUMN score SET NOT NULL", sql);
		Assert.contains("ALTER COLUMN score SET DEFAULT 0", sql);
	}

	function testPostgres_DropNotNull() {
		final sql = new SqlTranslator().ToSql(Alter(true, null, false));
		Assert.contains("ALTER COLUMN score DROP NOT NULL", sql);
	}

	function testMySql_ModifyColumn() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testSqlServer_AlterColumnNullability() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}
}
