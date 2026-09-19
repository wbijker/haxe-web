package suites;

import codequery.InsertStrategy;
import codequery.QualifiedTableName;
import codequery.execution.DatabaseConfiguration;
import codequery.execution.Statement;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.SqlAssert;
import codequery.testing.TestCase;

/**
	`BoundCompositeInsertTests.cs`: inserting a composite value. The row itself — `ROW(…)::Spec` —
	is not something a parameter can carry, which is not the same as saying none of it can: the
	fields are ordinary values, and the row is built around them in the statement.
**/
class BoundCompositeInsertTests extends TestCase {
	static function Spec(fields:Array<ISqlExpression>):ObjectConstSqlExpression {
		return new ObjectConstSqlExpression(fields, "Spec");
	}

	static function RenderedInsert(value:ISqlExpression):Statement {
		final table = new TableSqlSource(new QualifiedTableName("kind_parts"), "t0");
		final insert = new InsertExpression(table);
		insert.Strategy = new InsertStrategy();
		insert.Columns.push(new ColumnSqlExpression(table, "AsNative", SqlUnknown));
		insert.Values.push([value]);

		return new DatabaseConfiguration(new SqlTranslator()).Render(insert);
	}

	static function Values(rendered:Statement):Array<Dynamic> {
		return rendered.Parameters.map(SqlAssert.ValueOfConst);
	}

	function testACompositeIsBuiltAroundItsBoundFields() {
		final rendered = RenderedInsert(Spec([Expr.constString("nylon"), Expr.constInt(6)]));

		Assert.contains("VALUES (ROW($1, $2)::Spec)", rendered.Sql);
		Assert.equals(["nylon", 6], Values(rendered));
	}

	function testACompositeInsideOne_BindsEveryFieldOfBoth() {
		final rendered = RenderedInsert(Spec([
			Expr.constString("nylon"),
			new ObjectConstSqlExpression([Expr.constString("ZAR"), Expr.constFloat(1.5)], "Rate")
		]));

		Assert.contains("VALUES (ROW($1, ROW($2, $3)::Rate)::Spec)", rendered.Sql);
		Assert.equals(["nylon", "ZAR", 1.5], Values(rendered));
	}

	function testACompositeBesideOrdinaryValues_KeepsThePlaceholdersInOrder() {
		final table = new TableSqlSource(new QualifiedTableName("kind_parts"), "t0");
		final insert = new InsertExpression(table);
		insert.Strategy = new InsertStrategy();
		insert.Columns.push(new ColumnSqlExpression(table, "Name", SqlText));
		insert.Columns.push(new ColumnSqlExpression(table, "AsNative", SqlUnknown));
		insert.Columns.push(new ColumnSqlExpression(table, "Grade", SqlInt));
		insert.Values.push([
			Expr.constString("bearing"),
			Spec([Expr.constString("nylon"), Expr.constInt(6)]),
			Expr.constInt(4)
		]);

		final rendered = new DatabaseConfiguration(new SqlTranslator()).Render(insert);

		Assert.contains("VALUES ($1, ROW($2, $3)::Spec, $4)", rendered.Sql);
		Assert.equals(["bearing", "nylon", 6, 4], Values(rendered));
	}

	function testADialectWithoutCompositeTypes_SaysSo() {
		Assert.skip("SqliteSqlDriver: no SQLite dialect in this port to refuse a composite");
	}
}
