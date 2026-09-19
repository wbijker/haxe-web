package suites;

import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `InlineBinaryLiteralTests.cs` — bytes written into a statement. `SqlConstValue` has no binary kind here. */
class InlineBinaryLiteralTests extends TestCase {
	function testPostgres_WritesAByteaLiteral() {
		Assert.skip("byte[] literal: SqlConstValue has no binary kind in this port; the bytea spelling is PostgresSqlDriver's");
	}

	function testSqliteAndMySql_WriteTheStandardHexLiteral() {
		Assert.skip("byte[] literal: SqlConstValue has no binary kind in this port; SqliteSqlDriver/MySqlSqlDriver: no other dialects");
	}

	function testSqlServer_WritesAZeroXLiteral() {
		Assert.skip("byte[] literal: SqlConstValue has no binary kind in this port; MssqlSqlDriver: no SQL Server dialect");
	}

	function testInlineInsertedBytesReadBackUnchanged() {
		Assert.skip("byte[] literal: SqlConstValue has no binary kind in this port; needs a database: eval has none (PHP runtime only)");
	}
}
