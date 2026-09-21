package suites;

import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/**
	`SqlCastExpressionTests.cs` — `SqlCastExpression`: a cast is a construct of the language, not a
	call of a function called `CastToInt`. The target type is the operand's peer, so a type this
	port never heard of can be cast to as easily as one it defined.

	The C# theories are one test per row here, named for the row.
**/
class SqlCastExpressionTests extends TestCase {
	static function value():ISqlExpression {
		return Expr.constInt(1);
	}

	static function sql(type:SqlType):String {
		return new SqlTranslator().RenderExpression(new SqlCastExpression(value(), type));
	}

	static function mysql(type:SqlType):String {
		return new codequery.mysql.MySqlSqlTranslator().RenderExpression(new SqlCastExpression(value(), type));
	}

	// ---- each dialect's own spelling ---------------------------------------------------------------

	function testPostgres_Int() {
		Assert.equals("CAST(1 AS INTEGER)", sql(SqlInt));
	}

	function testPostgres_BigInt() {
		Assert.equals("CAST(1 AS BIGINT)", sql(SqlBigInt));
	}

	function testPostgres_SmallInt() {
		Assert.equals("CAST(1 AS SMALLINT)", sql(SqlSmallInt));
	}

	function testPostgres_Double() {
		Assert.equals("CAST(1 AS DOUBLE PRECISION)", sql(SqlFloat));
	}

	function testPostgres_Float() {
		Assert.equals("CAST(1 AS REAL)", sql(SqlReal));
	}

	function testPostgres_Decimal() {
		Assert.skip("PostgresSqlDriver: NUMERIC is PostgreSQL's spelling of a bare DECIMAL; this port's decimal carries its precision");
	}

	function testPostgres_VarChar() {
		Assert.equals("CAST(1 AS TEXT)", sql(SqlText));
	}

	function testPostgres_Boolean() {
		Assert.equals("CAST(1 AS BOOLEAN)", sql(SqlBool));
	}

	function testPostgres_DateTime() {
		Assert.equals("CAST(1 AS TIMESTAMP)", sql(SqlTimestamp));
	}

	function testSqlServer_Int() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_BigInt() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_SmallInt() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_Double() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_Float() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_Decimal() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_VarChar() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_Boolean() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_DateTime() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testMySql_Int() {
		Assert.equals("CAST(1 AS SIGNED)", mysql(SqlInt));
	}

	function testMySql_BigInt() {
		Assert.equals("CAST(1 AS SIGNED)", mysql(SqlBigInt));
	}

	function testMySql_SmallInt() {
		Assert.equals("CAST(1 AS SIGNED)", mysql(SqlSmallInt));
	}

	function testMySql_Double() {
		Assert.equals("CAST(1 AS DOUBLE)", mysql(SqlFloat));
	}

	function testMySql_Float() {
		Assert.equals("CAST(1 AS FLOAT)", mysql(SqlReal));
	}

	function testMySql_Decimal() {
		Assert.equals("CAST(1 AS DECIMAL(10, 2))", mysql(SqlDecimal(10, 2)));
	}

	function testMySql_VarChar() {
		Assert.equals("CAST(1 AS CHAR)", mysql(SqlText));
	}

	function testMySql_Boolean() {
		Assert.equals("CAST(1 AS UNSIGNED)", mysql(SqlBool));
	}

	function testMySql_DateTime() {
		Assert.equals("CAST(1 AS DATETIME)", mysql(SqlTimestamp));
	}

	function testSqlite_Int() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testSqlite_BigInt() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testSqlite_SmallInt() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testSqlite_Double() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testSqlite_Float() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testSqlite_Decimal() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testSqlite_VarChar() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testSqlite_Boolean() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testSqlite_ConvertsToDateWithAFunction() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	// ---- a type core has never heard of ------------------------------------------------------------

	function testATypeCoreDoesNotKnow_IsNamedByTheCaller() {
		final driver = new SqlTranslator();

		Assert.equals("CAST('{}' AS jsonb)",
			driver.RenderExpression(new SqlCastExpression(Expr.constString("{}"), SqlNamed("jsonb"))));

		Assert.equals("CAST(1 AS tsvector)",
			driver.RenderExpression(new SqlCastExpression(value(), SqlNamed("tsvector"))));
	}

	function testATypeADialectCannotCastTo_IsRefused() {
		// The port has no blob type; a cast to a type it cannot name is what it refuses.
		final error = Assert.throwsMessage(() -> sql(SqlUnknown));

		Assert.contains("cast", error);
	}

	// ---- what the tree holds -----------------------------------------------------------------------

	function testTheTargetTypeIsPartOfTheExpression() {
		final operand = Expr.constInt(1);
		final converted = new SqlCastExpression(operand, SqlDecimal(10, 2));

		Assert.equals(SqlType.SqlDecimal(10, 2), converted.Type);
		Assert.isTrue(operand == converted.Value);

		// A type named by the caller is carried as its name.
		final named = new SqlCastExpression(value(), SqlNamed("jsonb"));
		Assert.equals(SqlType.SqlNamed("jsonb"), named.Type);
	}

	function testCastIsNotAFunctionName() {
		Assert.skip("SqlFunctions.IsKnown: no function-name registry in this port");
	}
}
