package suites;

import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `IndexIncludeUsingTests.cs`: covering (INCLUDE) columns and the USING access method on CREATE INDEX. */
class IndexIncludeUsingTests extends TestCase {
	static function Index(?include:Array<String>, ?method:String):CreateIndexExpression {
		return new CreateIndexExpression("orders", "ix_orders_customer", [new IndexColumnDefinition("CustomerId")], false, false, null,
			null, false, include, method);
	}

	function testPostgres_UsingAndInclude() {
		final sql = new SqlTranslator().ToSql(Index(["Total", "Status"], "gin"));
		Assert.contains("ON orders USING gin (CustomerId) INCLUDE (Total, Status)", sql);
	}

	function testSqlServer_Include_NoUsing() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_UsingMethod_Throws() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testMySql_Include_Throws() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}
}
