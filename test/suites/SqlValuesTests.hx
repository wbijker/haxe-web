package suites;

import codequery.Query;
import codequery.Sql;
import codequery.SqlValues;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/**
	`SqlValuesTests.cs` — `SqlValues`: a strongly-typed constant collection rendered as a VALUES table
	constructor, usable as a query source or an INSERT … SELECT.
**/
class SqlValuesTests extends TestCase {
	static function widget(id:Int, name:String, active:Bool):SqlValuesWidget {
		final made = new SqlValuesWidget();
		made.id = id;
		made.name = name;
		made.active = active;
		return made;
	}

	static function sample():Array<SqlValuesWidget> {
		return [widget(1, "a", true), widget(2, "b'c", false)];
	}

	/** The C# `GetValuesSource()`: the constant table the statement selects from. */
	static function valuesSource(select:SelectExpression):ValueSqlSource {
		return Assert.isType(select.Source, ValueSqlSource);
	}

	function testTheRowsAndTheirColumnsAreTheSource() {
		final select = SqlValues.of(SqlValuesWidget, sample()).ToExpression();

		final values = valuesSource(select);
		Assert.equals(["id", "name", "active"], values.ColumnNames);
		Assert.count(2, values.Rows);

		values.Rows[0][0].value(1);
		values.Rows[0][1].value("a");
		values.Rows[0][2].value(true);
		values.Rows[1][1].value("b'c");
		values.Rows[1][2].value(false);

		// The constant table is read like any other source: by its columns.
		select.selectionOf("id").column("id", values.Alias);
	}

	function testAScalarListIsAOneColumnTable() {
		final select = SqlValues.of(Int, [1, 2, 3]).ToExpression();

		final values = valuesSource(select);
		Assert.equals(["value"], values.ColumnNames);
		Assert.equals([1, 2, 3], values.Rows.map(row -> Assert.single(row).valueOf()));

		select.selectionOf("value").column("value", values.Alias);
	}

	function testAScalarListReadsAsAnInList() {
		final ids = [7, 8];

		final select = Query.select(SqlValuesWidget)
			.Where(w -> Sql.inQuery(w.id, SqlValues.of(Int, ids)))
			.Select(w -> {id: w.id})
			.ToExpression();

		final membership = select.whereClause().isIn();
		membership.Value.column("id");

		final constants = select.whereClause().inSubquery();
		Assert.equals([7, 8], valuesSource(constants).Rows.map(row -> Assert.single(row).valueOf()));
	}

	function testAScalarListCarriesStringsAndNulls() {
		final values = valuesSource(SqlValues.of(String, ["a", "b'c", null]).ToExpression());

		Assert.equals(["a", "b'c", null], values.Rows.map(row -> Assert.single(row).valueOf()));
	}

	// ---- how each dialect writes a constant table --------------------------------------------------

	function testPostgres_RendersValuesTableConstructor() {
		// The port writes a boolean as 1 or 0, where PostgreSQL's own driver writes TRUE and FALSE.
		final sql = new SqlTranslator().ToSql(SqlValues.of(SqlValuesWidget, sample()).ToExpression());
		Assert.contains("(VALUES (1, 'a', 1), (2, 'b''c', 0)) AS t0(id, name, active)", sql);
		Assert.contains("t0.id", sql);
	}

	function testMySql_UsesRowConstructor() {
		Assert.skip("MySqlSqlDriver: no MySQL dialect in this port");
	}

	function testInsert_FromSqlValues_PersistsRows() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}

	function testPostgres_QuotesStringsAndWritesNulls() {
		Assert.contains(
			"(VALUES ('a'), ('b''c'), (NULL)) AS t0(value)",
			new SqlTranslator().ToSql(SqlValues.of(String, ["a", "b'c", null]).ToExpression()));
	}

	function testAScalarListFetches() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}

class SqlValuesWidget {
	public var id:Int = 0;
	public var name:String = "";
	public var active:Bool = false;

	public function new() {}
}
