package suites;

import codequery.Query;
import codequery.SqlDate;
import codequery.Window;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/**
	`WindowSpecTests.cs` — the `OVER (…)` clause written as a spec chain: partition keys, ordering
	terms each with their own direction and null placement, and a frame — in the order SQL writes
	them.
**/
class WindowSpecTests extends TestCase {
	/** The C# `AssertWindowFrame`. */
	static function frameOf(frame:Null<WindowFrame>, kind:FrameKind):WindowFrame {
		Assert.notNull(frame);
		Assert.equals(kind, frame.Kind);
		return frame;
	}

	function testSeveralOrderTerms_KeepTheOrderTheyAreWrittenIn() {
		final window = Query.select(Telemetry)
			.Select(r -> Window.rowNumber(w -> w
				.PartitionBy(r.tripNumber)
				.OrderByDesc(r.timestamp)
				.OrderByDesc(r.instanceId)))
			.ToExpression().selectionAt(0).windowFunction(RowNumber);

		Assert.single(window.PartitionBy).column("tripNumber");

		Assert.count(2, window.OrderBy);
		window.OrderBy[0].Expression.column("timestamp");
		window.OrderBy[1].Expression.column("instanceId");
	}

	function testEachTerm_HasItsOwnDirection() {
		final window = Query.select(Telemetry)
			.Select(r -> Window.rowNumber(w -> w
				.PartitionBy(r.tripNumber)
				.OrderByDesc(r.timestamp)
				.OrderBy(r.instanceId)))
			.ToExpression().selectionAt(0).windowFunction(RowNumber);

		Assert.isFalse(window.OrderBy[0].Ascending);
		Assert.isTrue(window.OrderBy[1].Ascending);
	}

	function testATerm_CanSayWhereItsNullsSort() {
		final window = Query.select(Telemetry)
			.Select(r -> Window.rowNumber(w -> w
				.OrderByDesc(r.timestamp, NullsOrdering.Last)
				.OrderBy(r.instanceId, NullsOrdering.First)))
			.ToExpression().selectionAt(0).windowFunction(RowNumber);

		Assert.equals(NullsOrdering.Last, window.OrderBy[0].Nulls);
		Assert.equals(NullsOrdering.First, window.OrderBy[1].Nulls);
	}

	function testPartitionBy_TakesSeveralKeys() {
		final window = Query.select(Telemetry)
			.Select(r -> Window.rank(w -> w
				.PartitionBy(r.tripNumber, r.instanceId)
				.OrderByDesc(r.timestamp)))
			.ToExpression().selectionAt(0).windowFunction(Rank);

		Assert.count(2, window.PartitionBy);
		window.PartitionBy[0].column("tripNumber");
		window.PartitionBy[1].column("instanceId");
	}

	function testPartitionBy_Accumulates() {
		final window = Query.select(Telemetry)
			.Select(r -> Window.rank(w -> w
				.PartitionBy(r.tripNumber)
				.PartitionBy(r.instanceId)
				.OrderBy(r.timestamp)))
			.ToExpression().selectionAt(0).windowFunction(Rank);

		Assert.count(2, window.PartitionBy);
		window.PartitionBy[0].column("tripNumber");
		window.PartitionBy[1].column("instanceId");
	}

	function testTheValueFunctions_TakeTheSameSpec() {
		final window = Query.select(Telemetry)
			.Select(r -> Window.lag(r.instanceId, 1, w -> w
				.PartitionBy(r.tripNumber)
				.OrderByDesc(r.timestamp)
				.OrderByDesc(r.id)))
			.ToExpression().selectionAt(0).windowFunction(Lag);

		window.Arguments[0].column("instanceId");
		window.Arguments[1].value(1);

		Assert.single(window.PartitionBy).column("tripNumber");
		Assert.count(2, window.OrderBy);
	}

	function testAFrame_FollowsTheOrdering() {
		final window = Query.select(Telemetry)
			.Select(r -> Window.rowNumber(w -> w
				.PartitionBy(r.tripNumber)
				.OrderBy(r.timestamp)
				.RowsBetween(UnboundedPreceding, CurrentRow)))
			.ToExpression().selectionAt(0).windowFunction(RowNumber);

		final frame = frameOf(window.Frame, Rows);
		Assert.equals(WindowBound.UnboundedPreceding, frame.Start);
		Assert.equals(WindowBound.CurrentRow, frame.End);
	}

	function testARangeFrame_SaysRange() {
		final window = Query.select(Telemetry)
			.Select(r -> Window.rowNumber(w -> w
				.OrderBy(r.timestamp)
				.RangeBetween(Preceding(1), Following(1))))
			.ToExpression().selectionAt(0).windowFunction(RowNumber);

		final frame = frameOf(window.Frame, Range);
		Assert.equals(WindowBound.Preceding(1), frame.Start);
		Assert.equals(WindowBound.Following(1), frame.End);
	}

	function testAnEmptySpec_IsOverNothing() {
		final window = Query.select(Telemetry)
			.Select(r -> Window.rowNumber(w -> w))
			.ToExpression().selectionAt(0).windowFunction(RowNumber);

		Assert.empty(window.PartitionBy);
		Assert.empty(window.OrderBy);
		Assert.isNull(window.Frame);
	}

	function testOrderByAlone_LeavesOutThePartition() {
		final window = Query.select(Telemetry)
			.Select(r -> Window.rowNumber(w -> w.OrderByDesc(r.timestamp)))
			.ToExpression().selectionAt(0).windowFunction(RowNumber);

		Assert.empty(window.PartitionBy);
		Assert.single(window.OrderBy).Expression.column("timestamp");
		Assert.isFalse(window.OrderBy[0].Ascending);
	}
}

@tableName("telemetry")
class Telemetry {
	public var id:Int = 0;
	public var tripNumber:String = "";
	public var timestamp:SqlDate;
	public var instanceId:Int = 0;

	public function new() {}
}
