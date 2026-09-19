package suites;

import codequery.Query;
import codequery.sqldrivers.SqlTranslator;
import codequery.testing.Assert;
import codequery.testing.TestCase;
import entities.constructedvalue.Entities;

/**
	`ConstructedValueTests.cs` — a value built in a query lambda is that value, not a row of the
	arguments its constructor was given. The values the C# builds are a `Guid` and a `TimeSpan`,
	neither of which Haxe has a type for.
**/
class ConstructedValueTests extends TestCase {
	function testAConstructedGuid_IsTheGuid() {
		Assert.skip("Guid/ObjectConstSqlExpression: no Guid type in Haxe to construct");
	}

	function testAConstructedTimeSpan_IsTheInterval() {
		Assert.skip("TimeSpan/IntervalSqlExpression: no TimeSpan type in Haxe to construct");
	}

	/** The other side of the rule: a constructor whose arguments read the row is a projection, and stays one. */
	function testAProjection_IsStillAProjection() {
		final sql = new SqlTranslator().ToSql(Query.select(Job)
			.Select(j -> {id: j.id, name: j.name})
			.ToExpression());

		Assert.contains("t0.id", sql);
		Assert.contains("t0.name", sql);
	}
}
