package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.stringpattern.Entities;

using StringTools;
using codequery.testing.SqlAssert;

/**
	`StringPatternTests.cs` — `contains`, `startsWith` and `endsWith` where what is searched for is
	not written at the call site. `String` has these through `StringTools`, which is what the lambda
	is typed against.
**/
class StringPatternTests extends TestCase {
	static function stringOperation(e:ISqlExpression, type:StringOperationType, ?column:String,
			?term:String):StringOperationExpression {
		final operation = e.expression(StringOperationExpression);
		Assert.equals(type, operation.OperationType);
		if (column != null) {
			operation.Operand.column(column);
		}
		if (term != null) {
			operation.Pattern.value(term);
		}
		return operation;
	}

	/** A term written at the call site is still the literal it always was. */
	function testAWrittenTermIsStillALiteral() {
		// The pattern is one value, so the operation carries it whole rather than building it up.
		stringOperation(Query.select(Part).Where(p -> p.name.contains("bolt")).Select(p -> {id: p.id}).ToExpression()
			.whereClause(), Contains, "name", "bolt");
		stringOperation(Query.select(Part).Where(p -> p.name.startsWith("bo")).Select(p -> {id: p.id}).ToExpression()
			.whereClause(), StartsWith, "name", "bo");
		stringOperation(Query.select(Part).Where(p -> p.name.endsWith("lt")).Select(p -> {id: p.id}).ToExpression()
			.whereClause(), EndsWith, "name", "lt");
	}

	/** A term the statement cannot write out is carried as it is — bound, or a column. */
	function testATermFromAVariableIsCarriedAsAValue() {
		final term = "bolt";

		final cases = [
			{
				expression: Query.select(Part).Where(p -> p.name.contains(term)).Select(p -> {id: p.id}).ToExpression().whereClause(),
				type: StringOperationType.Contains
			},
			{
				expression: Query.select(Part).Where(p -> p.name.startsWith(term)).Select(p -> {id: p.id}).ToExpression().whereClause(),
				type: StringOperationType.StartsWith
			},
			{
				expression: Query.select(Part).Where(p -> p.name.endsWith(term)).Select(p -> {id: p.id}).ToExpression().whereClause(),
				type: StringOperationType.EndsWith
			},
		];
		for (c in cases) {
			final operation = stringOperation(c.expression, c.type);
			operation.Operand.column("name");
			operation.Pattern.bound("bolt");
		}
	}

	/** Another column works for the same reason: it is a value the statement cannot write out. */
	function testSoIsAnotherColumn() {
		final operation = stringOperation(
			Query.select(Part).Where(p -> p.name.contains(p.sku)).Select(p -> {id: p.id}).ToExpression().whereClause(),
			Contains);

		operation.Operand.column("name");
		operation.Pattern.column("sku");
	}

	// ---- what the translator makes of the pattern ------------------------------------------------------

	function testAWrittenTermRendersAsOneLiteral() {
		final sql = new SqlTranslator().ToSql(
			Query.select(Part).Where(p -> p.name.contains("bolt")).Select(p -> {id: p.id}).ToExpression());

		Assert.contains("t0.name LIKE '%bolt%'", sql);
	}

	/**
		The wildcards are concatenated around a bound term. C# shows PostgreSQL's `||` and MySQL's
		`CONCAT`; the one dialect here concatenates as PostgreSQL does, written to read.
	**/
	function testEachDialectConcatenatesItsOwnWay() {
		final term = "bolt";
		final query = Query.select(Part).Where(p -> p.name.contains(term)).Select(p -> {id: p.id});

		final translator = new SqlTranslator();
		translator.InlineValues = true;
		Assert.contains("('%' || 'bolt' || '%')", translator.ToSql(query.ToExpression()));
	}

	function testItFindsTheRows() {
		Assert.skip("needs a database: eval has none (PHP runtime only)");
	}
}
