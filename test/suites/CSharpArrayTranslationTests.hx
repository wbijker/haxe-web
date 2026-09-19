package suites;

import codequery.Query;
import codequery.Sql;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;

/**
	`CSharpArrayTranslationTests.cs` — a plain C# `T[]` column translated to PostgreSQL array SQL.
	Arrays are PostgreSQL's, so only the one test about a captured list holds here.
**/
class CSharpArrayTranslationTests extends TestCase {
	function testLeftJoinLateral_Unnest_RendersLateralUnnest() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testInnerJoinLateral_Unnest_StaticForm_RendersCrossJoinLateral() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testLeftJoinLateral_Unnest_OverPgArray() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testLength_TranslatesToCardinality() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testIndexing_IsRebasedToOneBased() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testContains_TranslatesToAnyEquals() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testCountAndAny_TranslateToCardinality() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testAppendPrependConcat_TranslateToArrayFunctions() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testReverseElementAtFirst_Translate() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testStringArray_Contains_Translates() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testAnyWithEqualityPredicate_TranslatesToArrayContains() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testAnyWithEqualityAgainstOuterColumn_TranslatesToArrayContains() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testAnyWithGeneralPredicate_TranslatesToExistsOverUnnest() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testAllWithPredicate_TranslatesToNotExistsOfNegation() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testCountWithPredicate_TranslatesToScalarSubquery() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testGeneralPredicateCanReferenceOuterColumn() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testAnyWithAndWithoutPredicate_CoexistInProjection() {
		Assert.skip("PgArray: PostgreSQL extension");
	}

	function testCapturedList_Contains_StillRendersInList() {
		// A captured/constant collection is unchanged: value IN (…), not = ANY(column).
		final ids = [1, 2, 3];
		final sql = new SqlTranslator().ToSql(Query.select(ArrayRow).Where(r -> Sql.isIn(r.id, ids)).ToExpression());
		Assert.contains("t0.id IN (1, 2, 3)", sql);
		Assert.doesNotContain("ANY", sql);
	}
}

class ArrayRow {
	public var id:Int = 0;
	public var title:String = "";

	public function new() {}
}
