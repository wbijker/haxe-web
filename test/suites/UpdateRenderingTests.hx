package suites;

import codequery.QualifiedTableName;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`UpdateRenderingTests.cs`: UPDATE rendering regressions — decimal literals must be
	culture-invariant, and the target is aliased where the dialect allows it.
**/
class UpdateRenderingTests extends TestCase {
	static function PriceUpdate():UpdateExpression {
		final source = new TableSqlSource(new QualifiedTableName("books"), "t0");
		final update = new UpdateExpression(source);
		update.Assignments.push(new SetAssignment(
			new ColumnSqlExpression(source, "Price", SqlDecimal(10, 2)), Expr.constFloat(19.99)));
		update.Where = new BinarySqlExpression(
			new ColumnSqlExpression(source, "Id", SqlInt), Equal, Expr.constInt(1));
		return update;
	}

	function testJsonDocument_RendersAsQuotedJsonText_NotItsTypeName() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	function testJsonDocument_EscapesQuotesInItsText() {
		Assert.skip("JsonExpression: JSON not ported");
	}

	function testDecimalLiteral_RendersInvariant_NotWithLocaleSeparator() {
		// Regardless of the machine's locale, a decimal renders with a '.' — a ',' would break the SQL.
		Assert.contains("= 19.99", new SqlTranslator().ToSql(PriceUpdate()));
	}

	function testSqlServer_Update_UsesAliasedFromForm() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	function testOtherDialects_Update_AliasTheTargetDirectly() {
		Assert.contains("UPDATE books AS t0", new SqlTranslator().ToSql(PriceUpdate()));
	}
}
