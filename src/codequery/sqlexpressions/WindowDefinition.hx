package codequery.sqlexpressions;

/**
	A window written out where it is used, rather than named on the statement.

	`OVER (PARTITION BY … ORDER BY …)` says the same as `OVER w` with a `WINDOW w AS (…)` beside it;
	which reads better depends on whether more than one thing reads the window.
**/
class WindowDefinition {
	public final PartitionBy:Array<ISqlExpression>;
	public final OrderBy:Array<OrderByExpression>;
	public final Frame:Null<WindowFrame>;

	public function new(partitionBy:Array<ISqlExpression>, orderBy:Array<OrderByExpression>, ?frame:WindowFrame) {
		this.PartitionBy = partitionBy;
		this.OrderBy = orderBy;
		this.Frame = frame;
	}
}
