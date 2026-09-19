package codequery;

/**
	The aggregates of a query over 6 rows, as `SelectAggregation` and `Having` see them — C#'s
	`IAggregateSet<T1, T2, T3, T4, T5, T6>`. Each selector takes every row the query has, in the order they were
	joined. As with `IAggregateSet`, nothing here runs: the projection is converted while compiling.
**/
extern class IAggregateSet6<T1, T2, T3, T4, T5, T6> {
	/** `COUNT(*)` — how many rows are in the group. */
	public function count():Aggregate6<T1, T2, T3, T4, T5, T6, Int>;

	/** The grouping key, or one member of it, selected beside the aggregates. */
	public function key<TValue>(selector:(T1, T2, T3, T4, T5, T6)->TValue):TValue;

	/** `COUNT(DISTINCT x)`. */
	public function countDistinct<TValue>(selector:(T1, T2, T3, T4, T5, T6)->TValue):Aggregate6<T1, T2, T3, T4, T5, T6, Int>;

	/** `SUM(x)`. */
	public function sum<TValue>(selector:(T1, T2, T3, T4, T5, T6)->TValue):Aggregate6<T1, T2, T3, T4, T5, T6, TValue>;

	/** `AVG(x)`. */
	public function avg<TValue>(selector:(T1, T2, T3, T4, T5, T6)->TValue):Aggregate6<T1, T2, T3, T4, T5, T6, Float>;

	/** `MIN(x)`. */
	public function min<TValue>(selector:(T1, T2, T3, T4, T5, T6)->TValue):Aggregate6<T1, T2, T3, T4, T5, T6, TValue>;

	/** `MAX(x)`. */
	public function max<TValue>(selector:(T1, T2, T3, T4, T5, T6)->TValue):Aggregate6<T1, T2, T3, T4, T5, T6, TValue>;

	/** `ROW_NUMBER()` — which row this is within its window. */
	public function rowNumber():Aggregate6<T1, T2, T3, T4, T5, T6, Int>;

	/** `RANK()`. */
	public function rank():Aggregate6<T1, T2, T3, T4, T5, T6, Int>;

	/** `DENSE_RANK()`. */
	public function denseRank():Aggregate6<T1, T2, T3, T4, T5, T6, Int>;

	/** `LEAD(x, offset)`. */
	public function lead<TValue>(selector:(T1, T2, T3, T4, T5, T6)->TValue, ?offset:Int):Aggregate6<T1, T2, T3, T4, T5, T6, TValue>;

	/** `LAG(x, offset)`. */
	public function lag<TValue>(selector:(T1, T2, T3, T4, T5, T6)->TValue, ?offset:Int):Aggregate6<T1, T2, T3, T4, T5, T6, TValue>;

	/** `FIRST_VALUE(x)` within the window. */
	public function firstValue<TValue>(selector:(T1, T2, T3, T4, T5, T6)->TValue):Aggregate6<T1, T2, T3, T4, T5, T6, TValue>;

	/** `LAST_VALUE(x)` within the window. */
	public function lastValue<TValue>(selector:(T1, T2, T3, T4, T5, T6)->TValue):Aggregate6<T1, T2, T3, T4, T5, T6, TValue>;
}
