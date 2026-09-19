package suites;

import codequery.Query;
import codequery.Window;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/** `WindowFunctionTests.cs`. */
class WindowFunctionTests extends TestCase {
	static function frameOf(frame:Null<WindowFrame>, kind:FrameKind):WindowFrame {
		Assert.notNull(frame);
		Assert.equals(kind, frame.Kind);
		return frame;
	}

	function testRowNumber_CarriesItsPartitionAndDescendingOrder() {
		final select = Query.select(WindowFunctionRow)
			.Select(b -> {
				authorId: b.authorId,
				rn: Window.rowNumber(w -> w.PartitionBy(b.authorId).OrderByDesc(b.revenue))
			})
			.ToExpression();

		final rowNumber = select.selectionOf("rn").windowFunction(RowNumber);
		Assert.empty(rowNumber.Arguments);
		Assert.single(rowNumber.PartitionBy).column("authorId");
		Assert.single(rowNumber.OrderBy).Expression.column("revenue");
		Assert.isFalse(rowNumber.OrderBy[0].Ascending);
	}

	function testRowNumber_DefaultsToAscendingOrder() {
		final select = Query.select(WindowFunctionRow)
			.Select(b -> {rn: Window.rowNumber(w -> w.PartitionBy(b.authorId).OrderBy(b.revenue))})
			.ToExpression();

		final rowNumber = select.selectionOf("rn").windowFunction(RowNumber);
		Assert.isTrue(Assert.single(rowNumber.OrderBy).Ascending);
	}

	function testNtile_TakesItsBucketCount() {
		final ntile = Query.select(WindowFunctionRow)
			.Select(r -> Window.ntile(4, w -> w.PartitionBy(r.authorId).OrderByDesc(r.revenue)))
			.ToExpression().selectionAt(0).windowFunction(Ntile);

		Assert.single(ntile.Arguments).value(4);
		Assert.single(ntile.PartitionBy).column("authorId");
		Assert.isFalse(Assert.single(ntile.OrderBy).Ascending);
	}

	function testLagAndLead_TakeTheirColumnAndOffset() {
		final lag = Query.select(WindowFunctionRow)
			.Select(r -> Window.lag(r.revenue, 1, w -> w.PartitionBy(r.authorId).OrderByDesc(r.revenue)))
			.ToExpression().selectionAt(0).windowFunction(Lag);

		Assert.count(2, lag.Arguments);
		lag.Arguments[0].column("revenue");
		lag.Arguments[1].value(1);
		Assert.isFalse(Assert.single(lag.OrderBy).Ascending);

		final lead = Query.select(WindowFunctionRow)
			.Select(r -> Window.lead(r.revenue, 1, w -> w.PartitionBy(r.authorId).OrderBy(r.revenue)))
			.ToExpression().selectionAt(0).windowFunction(Lead);

		lead.Arguments[0].column("revenue");
		lead.Arguments[1].value(1);
		Assert.isTrue(Assert.single(lead.OrderBy).Ascending);
	}

	function testFirstAndLastValue_TakeTheirColumn() {
		final first = Query.select(WindowFunctionRow)
			.Select(r -> Window.firstValue(r.revenue, w -> w.PartitionBy(r.authorId).OrderByDesc(r.revenue)))
			.ToExpression().selectionAt(0).windowFunction(FirstValue);
		Assert.single(first.Arguments).column("revenue");

		final last = Query.select(WindowFunctionRow)
			.Select(r -> Window.lastValue(r.revenue, w -> w.PartitionBy(r.authorId).OrderByDesc(r.revenue)))
			.ToExpression().selectionAt(0).windowFunction(LastValue);
		Assert.single(last.Arguments).column("revenue");
	}

	function testRowNumber_WithFrame_CarriesBothBounds() {
		final select = Query.select(WindowFunctionRow)
			.Select(b -> {
				rn: Window.rowNumber(w -> w
					.PartitionBy(b.authorId)
					.OrderByDesc(b.revenue)
					.RowsBetween(Preceding(1), Following(1)))
			})
			.ToExpression();

		final rowNumber = select.selectionOf("rn").windowFunction(RowNumber);

		final frame = frameOf(rowNumber.Frame, Rows);
		Assert.equals(WindowBound.Preceding(1), frame.Start);
		Assert.equals(WindowBound.Following(1), frame.End);
	}
}

class WindowFunctionRow {
	public var authorId:Int = 0;
	public var revenue:Float = 0;

	public function new() {}
}
