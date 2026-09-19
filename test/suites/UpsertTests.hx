package suites;

import codequery.QualifiedTableName;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/** `UpsertTests.cs`: upsert (INSERT … ON CONFLICT) — a common statement rendered per driver. */
class UpsertTests extends TestCase {
	static function Insert(action:ConflictAction, ?updateColumns:Array<String>):InsertExpression {
		final source = new TableSqlSource(new QualifiedTableName("books"), "t0");
		final insert = new InsertExpression(source);
		insert.OnConflict = action;
		insert.Columns.push(new ColumnSqlExpression(source, "Isbn", SqlText));
		insert.Columns.push(new ColumnSqlExpression(source, "Title", SqlText));
		insert.Columns.push(new ColumnSqlExpression(source, "Price", SqlDecimal(10, 2)));
		insert.Values.push([Expr.constString("978"), Expr.constString("T"), Expr.constInt(9)]);
		insert.ConflictColumns.push("Isbn");
		if (updateColumns != null) {
			for (column in updateColumns) {
				insert.ConflictUpdateColumns.push(column);
			}
		}
		return insert;
	}

	function testPostgres_DoUpdate_UsesOnConflictExcluded() {
		final sql = new SqlTranslator().ToSql(Insert(DoUpdate));
		Assert.contains("ON CONFLICT (Isbn) DO UPDATE SET Title = EXCLUDED.Title, Price = EXCLUDED.Price", sql);
	}

	function testSqlite_DoNothing() {
		final sql = new SqlTranslator().ToSql(Insert(DoNothing));
		Assert.contains("ON CONFLICT (Isbn) DO NOTHING", sql);
	}

	function testPostgres_DoUpdate_ExplicitColumns() {
		final sql = new SqlTranslator().ToSql(Insert(DoUpdate, ["Title"]));
		Assert.contains("ON CONFLICT (Isbn) DO UPDATE SET Title = EXCLUDED.Title", sql);
		Assert.doesNotContain("Price", sql.substr(sql.indexOf("ON CONFLICT")));
	}

	function testMySql_UsesOnDuplicateKeyUpdate() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testMySql_DoNothing_IsNoOpSelfAssign() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testSqlServer_RendersMerge() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testSqlServer_DoNothing_OmitsMatchedClause() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}
}
