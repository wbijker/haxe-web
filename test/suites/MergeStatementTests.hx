package suites;

import codequery.QualifiedTableName;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`MergeStatementTests.cs`: the MERGE statement as data and its rendering.

	The C# names its sources `t` and `s`; the port names a statement's sources as it renders them,
	in order — the target is `t0` and the source `t1` — so they are built under those names here.
**/
class MergeStatementTests extends TestCase {
	static function Col(source:ISqlSource, name:String):ISqlExpression {
		return new ColumnSqlExpression(source, name, SqlInt);
	}

	static function BuildMerge():MergeExpression {
		final target = new TableSqlSource(new QualifiedTableName("accounts"), "t0");
		final source = new TableSqlSource(new QualifiedTableName("staging"), "t1");

		final on = new BinarySqlExpression(Col(target, "Id"), Equal, Col(source, "Id"));
		final merge = new MergeExpression(target, source, on);

		merge.Actions.push(new MergeWhenMatchedUpdate([new MergeAssignment("Balance", Col(source, "Balance"))]));
		merge.Actions.push(new MergeWhenNotMatchedInsert(["Id", "Balance"], [Col(source, "Id"), Col(source, "Balance")]));

		return merge;
	}

	function testPostgres_RendersStandardMerge() {
		final sql = new SqlTranslator().ToSql(BuildMerge());
		Assert.contains("MERGE INTO accounts AS t0", sql);
		Assert.contains("USING staging AS t1 ON t0.Id = t1.Id", sql);
		Assert.contains("WHEN MATCHED THEN UPDATE SET Balance = t1.Balance", sql);
		Assert.contains("WHEN NOT MATCHED THEN INSERT (Id, Balance) VALUES (t1.Id, t1.Balance)", sql);
		Assert.doesNotContain(";", sql);
	}

	function testSqlServer_TerminatesWithSemicolon() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testMatchedDelete_WithCondition() {
		final target = new TableSqlSource(new QualifiedTableName("accounts"), "t0");
		final source = new TableSqlSource(new QualifiedTableName("staging"), "t1");
		final on = new BinarySqlExpression(Col(target, "Id"), Equal, Col(source, "Id"));
		final merge = new MergeExpression(target, source, on);
		final cond = new BinarySqlExpression(new ColumnSqlExpression(source, "Closed", SqlBool), Equal, Expr.constBool(true));
		merge.Actions.push(new MergeWhenMatchedDelete(cond));

		final sql = new SqlTranslator().ToSql(merge);
		Assert.contains("WHEN MATCHED AND t1.Closed = 1 THEN DELETE", sql);
	}

	function testMySqlAndSqlite_Throw() {
		Assert.throws(() -> new codequery.mysql.MySqlSqlTranslator().ToSql(BuildMerge()));
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port for the second half");
	}
}
