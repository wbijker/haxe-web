package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.likeall.Entities;

using codequery.testing.SqlAssert;

/** `LikeAllTests.cs` — `DbFunctions.LikeAll` is `Sql.likeAll`: LIKE across all mapped columns except the key. */
class LikeAllTests extends TestCase {
	/**
		The arms of the OR the expansion built, left to right. Each is one column's LIKE, so the list
		of them is exactly the set of columns the term was compared against.
	**/
	static function arms(expression:ISqlExpression):Array<StringOperationExpression> {
		final or = Std.downcast(cast expression, BinarySqlExpression);
		if (or != null && or.Operator.match(Or)) {
			return arms(or.Left).concat(arms(or.Right));
		}
		final arm = expression.expression(StringOperationExpression);
		Assert.equals(StringOperationType.Contains, arm.Type);
		return [arm];
	}

	/** The name of the column an arm searches, whether or not it had to be cast to text first. */
	static function searchedColumn(arm:StringOperationExpression):String {
		final converted = Std.downcast(cast arm.Operand, SqlCastExpression);
		if (converted != null) {
			Assert.equals(SqlType.SqlText, converted.Type);
			return converted.Value.column().ColumnName;
		}
		return arm.Operand.column().ColumnName;
	}

	function testLikeAll_OrsAllColumns_ExceptPrimaryKey() {
		final found = arms(Query.select(Author).Where(a -> Sql.likeAll(a, "x")).ToExpression().whereClause());

		// Every mapped column but the key, each searching for the same term.
		Assert.equals(["name", "bio", "age"], found.map(searchedColumn));
		for (arm in found) {
			arm.Pattern.value("x");
		}
	}

	function testLikeAll_CastsNonTextColumns() {
		final found = arms(Query.select(Author).Where(a -> Sql.likeAll(a, "x")).ToExpression().whereClause());

		// A text column is searched as it stands; anything else is cast to text first.
		found.filter(a -> searchedColumn(a) == "name")[0].Operand.column("name");
		Assert.equals(SqlType.SqlText, found.filter(a -> searchedColumn(a) == "age")[0].Operand.castTo().Type);
	}

	function testLikeAll_ComposesWithOtherPredicates() {
		final and = Query.select(Author).Where(a -> Sql.likeAll(a, "x") && a.age > 5).ToExpression().whereBinary(And);

		Assert.equals(["name", "bio", "age"], arms(and.Left).map(searchedColumn));
		and.Right.comparison("age", GreaterThan, 5);
	}

	function testLikeAll_CompositeKey_ExcludesBothKeyColumns() {
		final found = arms(Query.select(Enrollment).Where(e -> Sql.likeAll(e, "a")).ToExpression().whereClause());

		// The key columns are selected like any other; what they must not do is join the comparison.
		Assert.equals(["grade"], found.map(searchedColumn));
	}

	/** The cast the expansion asks for is spelled by the dialect, and only the text shows which type name it reached for. */
	function testTheCastIsSpelledByTheDialect() {
		final sql = new SqlTranslator().ToSql(
			Query.select(Author).Where(a -> Sql.likeAll(a, "x")).ToExpression());

		Assert.contains("CAST(t0.age AS TEXT) LIKE '%x%'", sql);
	}
}
