package suites;

import codequery.Query;
import codequery.Window;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/** `WindowFunctionExtraTests.cs` — NTH_VALUE, PERCENT_RANK and CUME_DIST. */
class WindowFunctionExtraTests extends TestCase {
	function testNthValue_TakesItsColumnAndPosition() {
		final nth = Query.select(Score)
			.Select(s -> Window.nthValue(s.points, 2, w -> w.PartitionBy(s.teamId).OrderByDesc(s.points)))
			.ToExpression().selectionAt(0).windowFunction(NthValue);

		Assert.count(2, nth.Arguments);
		nth.Arguments[0].column("points");
		nth.Arguments[1].value(2);

		Assert.single(nth.PartitionBy).column("teamId");
		Assert.single(nth.OrderBy).Expression.column("points");
		Assert.isFalse(nth.OrderBy[0].Ascending);
	}

	function testPercentRank_TakesNoArguments() {
		final rank = Query.select(Score)
			.Select(s -> Window.percentRank(w -> w.PartitionBy(s.teamId).OrderBy(s.points)))
			.ToExpression().selectionAt(0).windowFunction(PercentRank);

		Assert.empty(rank.Arguments);
		Assert.single(rank.PartitionBy).column("teamId");
		Assert.isTrue(Assert.single(rank.OrderBy).Ascending);
	}

	function testCumeDist_TakesNoArgumentsEither() {
		final dist = Query.select(Score)
			.Select(s -> Window.cumeDist(w -> w.PartitionBy(s.teamId).OrderBy(s.points)))
			.ToExpression().selectionAt(0).windowFunction(CumeDist);

		Assert.empty(dist.Arguments);
		Assert.single(dist.PartitionBy).column("teamId");
		Assert.single(dist.OrderBy).Expression.column("points");
	}
}

class Score {
	public var teamId:Int = 0;
	public var points:Int = 0;

	public function new() {}
}
