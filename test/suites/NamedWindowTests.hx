package suites;

import codequery.DbAggregation;
import codequery.Query;
import codequery.SqlDate;
import codequery.sqldrivers.SqlTranslator;
import codequery.sqlexpressions.*;
import codequery.testing.Assert;
import codequery.testing.TestCase;

using codequery.testing.SqlAssert;

/**
	`NamedWindowTests.cs` — `INamedWindow`: a window defined once on the query and named by every
	aggregate that uses it, which is SQL's own answer to writing one specification out several times.
**/
class NamedWindowTests extends TestCase {
	static function frameOf(frame:Null<WindowFrame>, kind:FrameKind):WindowFrame {
		Assert.notNull(frame);
		Assert.equals(kind, frame.Kind);
		return frame;
	}

	/**
		Which of the statement's sources a column belongs to. A column names its source by the
		position of the lambda parameter it was reached through, which is what the C# reads as the
		source's alias.
	**/
	static function boundTo(column:ColumnSqlExpression, index:Int) {
		Assert.equals(index, Assert.isType(column.Source, ParameterSqlSource).Index, "source position");
	}

	/** The query from the brief: four aggregates over one moving-window definition. */
	static function movingWindow():SelectExpression {
		return Query.select(Reading)
			.Window(w -> w
				.PartitionBy(r -> r.deviceId)
				.OrderBy(r -> r.readingAt)
				.RowsBetween(Preceding(6), CurrentRow))
			.Select((r, w) -> {
				deviceId: r.deviceId,
				readingAt: r.readingAt,
				value: r.value,
				moving_avg: DbAggregation.avg(r.value).over(w),
				moving_min: DbAggregation.min(r.value).over(w),
				moving_max: DbAggregation.max(r.value).over(w),
				sample_count: DbAggregation.count().over(w),
			})
			.ToExpression();
	}

	function testTheWindowIsDefinedOnceAndNamed() {
		final select = movingWindow();

		final window = Assert.single(select.Windows);
		Assert.equals("w", window.Name);
		Assert.single(window.PartitionBy).column("device_id");
		Assert.single(window.OrderBy).Expression.column("reading_at");
		Assert.isTrue(window.OrderBy[0].Ascending);

		final frame = frameOf(window.Frame, Rows);
		Assert.equals(WindowBound.Preceding(6), frame.Start);
		Assert.equals(WindowBound.CurrentRow, frame.End);

		// Every aggregate names that one definition rather than carrying a copy of it.
		function assertOver(expression:ISqlExpression, type:AggregateType) {
			final aggregate = expression.aggregate(type);
			Assert.isTrue(aggregate.Windowed);
			Assert.isTrue(window == aggregate.Window, "the aggregate names the statement's own window");
			Assert.empty(aggregate.PartitionBy);
		}
		assertOver(select.selectionOf("moving_avg"), Avg);
		assertOver(select.selectionOf("moving_min"), Min);
		assertOver(select.selectionOf("moving_max"), Max);
		assertOver(select.selectionOf("sample_count"), Count);
	}

	function testTheWindowIsNotAJoin() {
		final select = movingWindow();

		Assert.equals("readings", select.selectTableName());
		Assert.empty(select.Joins);
		Assert.single(select.Windows);
	}

	function testTheClauseIsInItsPlace() {
		final sql = new SqlTranslator().ToSql(Query.select(Reading)
			.Window(w -> w.PartitionBy(r -> r.deviceId))
			.Select((r, w) -> {total: DbAggregation.sum(r.value).over(w)})
			.OrderByDesc(x -> x.total)
			.ToExpression());

		Assert.isTrue(sql.indexOf("WINDOW ") < sql.indexOf("ORDER BY"), sql);
	}

	function testWindowsCanBeNamed() {
		final select = Query.select(Reading)
			.Window(w -> w.PartitionBy(r -> r.deviceId), "by_device")
			.Select((r, w) -> {total: DbAggregation.sum(r.value).over(w)})
			.ToExpression();

		final window = select.window("by_device");
		Assert.single(window.PartitionBy).column("device_id");

		Assert.isTrue(window == select.selectionOf("total").aggregate(Sum).Window);
	}

	function testAWindowOverAJoin() {
		final select = Query.select(Reading)
			.InnerJoin(Query.select(Device), (r, d) -> r.deviceId == d.deviceId)
			.Window(w -> w.PartitionBy((r, d) -> d.site).OrderBy((r, d) -> r.readingAt))
			.Select((r, d, w) -> {site: d.site, avg: DbAggregation.avg(r.value).over(w)})
			.ToExpression();

		final window = select.window("w");
		boundTo(Assert.single(window.PartitionBy).column("site"), 1);
		boundTo(Assert.single(window.OrderBy).Expression.column("reading_at"), 0);

		final average = select.selectionOf("avg").aggregate(Avg);
		average.Argument.column("value");
		Assert.isTrue(window == average.Window);
	}

	function testSqlServer_WritesTheDefinitionOutInstead() {
		Assert.skip("MssqlSqlDriver: no SQL Server dialect in this port");
	}

	// ---- the spec form of over --------------------------------------------------------------------

	function testOverTakesASpecification() {
		final select = Query.select(Reading)
			.Select(r -> {
				running: DbAggregation.sum(r.value).over(w -> w
					.PartitionBy(r.deviceId)
					.OrderBy(r.readingAt)
					.RowsBetween(UnboundedPreceding, CurrentRow))
			})
			.ToExpression();

		final running = select.selectionOf("running").aggregate(Sum);
		running.Argument.column("value");
		Assert.isTrue(running.Windowed);

		// Written out on the spot, so the aggregate carries the specification itself rather than a name.
		Assert.isNull(running.Window);
		Assert.single(running.PartitionBy).column("device_id");
		Assert.single(running.OrderBy).Expression.column("reading_at");

		final frame = frameOf(running.Frame, Rows);
		Assert.equals(WindowBound.UnboundedPreceding, frame.Start);
		Assert.equals(WindowBound.CurrentRow, frame.End);
	}

	function testTheTwoArgumentOverIsUnchanged() {
		final select = Query.select(Reading)
			.Select(r -> {total: DbAggregation.sum(r.value).over(r.deviceId, r.readingAt)})
			.ToExpression();

		final total = select.selectionOf("total").aggregate(Sum);
		total.Argument.column("value");
		Assert.isTrue(total.Windowed);
		Assert.single(total.PartitionBy).column("device_id");
		Assert.single(total.OrderBy).Expression.column("reading_at");
		Assert.isTrue(total.OrderBy[0].Ascending);
		Assert.isNull(total.Frame);
	}
}

@tableName("readings")
class Reading {
	@columnName("device_id") public var deviceId:String;
	@columnName("reading_at") public var readingAt:SqlDate;
	@columnName("value") public var value:Float = 0;

	public function new() {}
}

@tableName("devices")
class Device {
	@columnName("device_id") public var deviceId:String;
	@columnName("site") public var site:String;

	public function new() {}
}
