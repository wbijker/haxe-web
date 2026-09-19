package suites;

import codequery.migrations.ColumnBackfill;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.SqlType;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`AddedColumnBackfillTests.cs`: a NOT NULL column arriving in a table that already holds rows.
	Those rows need a value and the column declares none, so one is written in and taken off again.
	A boolean's zero is written as this port writes a boolean, `0`; a date's as the first instant.
**/
class AddedColumnBackfillTests extends TestCase {
	static function Added(column:ColumnDefinition):AddColumnExpression {
		return new AddColumnExpression("Plan", column, null, ColumnBackfill.For(column));
	}

	static function Column(name:String, type:SqlType, nullable:Bool = false, ?defaultValue:ISqlExpression):ColumnDefinition {
		return new ColumnDefinition(name, type, nullable, defaultValue);
	}

	function testANotNullColumn_FillsTheRowsThatAreThere_AndKeepsNoDefault() {
		final sql = new SqlTranslator().ToSql(Added(Column("IsDeleted", SqlBool)));
		Assert.equals("ALTER TABLE Plan ADD COLUMN IsDeleted BOOLEAN NOT NULL DEFAULT 0;\n"
			+ "ALTER TABLE Plan ALTER COLUMN IsDeleted DROP DEFAULT", sql);
	}

	function testTheValueIsTheTypesOwnZero() {
		function Sql(type:SqlType):String {
			return new SqlTranslator().ToSql(Added(Column("c", type)));
		}
		Assert.contains("DEFAULT 0", Sql(SqlBool));
		Assert.contains("DEFAULT 0", Sql(SqlInt));
		Assert.contains("DEFAULT 0", Sql(SqlBigInt));
		Assert.contains("DEFAULT 0", Sql(SqlDecimal(0, 0)));
		Assert.contains("DEFAULT ''", Sql(SqlText));
		Assert.contains("DEFAULT '00000000-0000-0000-0000-000000000000'", Sql(SqlGuid));

		// The first instant, which is what a date's zero is here.
		Assert.contains("DEFAULT '0001-01-01 00:00:00'", Sql(SqlTimestamp));

		// Nothing is obviously empty about a document or a blob, so nothing is guessed.
		Assert.doesNotContain("DEFAULT", Sql(SqlJson));
		Assert.doesNotContain("DEFAULT", Sql(SqlBinary));
		Assert.doesNotContain("DEFAULT", Sql(SqlTime));
	}

	/** A column that says what it defaults to needs no help, and keeps what it says. */
	function testAColumnTheSchemaDefaults_KeepsItsOwnDefault() {
		final sql = new SqlTranslator().ToSql(Added(Column("Guests", SqlInt, false, new ConstSqlExpression(SqlConstInt(2)))));
		Assert.equals("ALTER TABLE Plan ADD COLUMN Guests INTEGER NOT NULL DEFAULT 2", sql);
		Assert.doesNotContain("DROP DEFAULT", sql);
	}

	/** A nullable column has a value for the existing rows already: NULL. */
	function testANullableColumn_IsAddedAsItAlwaysWas() {
		final sql = new SqlTranslator().ToSql(Added(Column("Note", SqlText, true)));
		Assert.equals("ALTER TABLE Plan ADD COLUMN Note TEXT", sql);
	}

	function testSqlServer_NamesTheDefaultItIsGoingToDrop() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testMySql_DropsTheDefaultTheSameWay() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testSqlite_KeepsTheDefaultBecauseItCannotDropIt() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port");
	}

	function testTheRowsAlreadyThere_TakeTheValue() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
