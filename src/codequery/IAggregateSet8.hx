package codequery;

/**
	The aggregates of a query over 8 rows, as `SelectAggregation` and `Having` see them — C#'s
	`IAggregateSet<T1, T2, T3, T4, T5, T6, T7, T8>`. Each selector takes every row the query has, in the order they were
	joined. As with `IAggregateSet`, nothing here runs: the projection is converted while compiling.
**/
extern class IAggregateSet8<T1, T2, T3, T4, T5, T6, T7, T8> {
	/** `COUNT(*)` — how many rows are in the group. */
	public function count():Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** The grouping key, or one member of it, selected beside the aggregates. */
	public function key<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7, T8)->TValue):TValue;

	/** `COUNT(DISTINCT x)`. */
	public function countDistinct<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7, T8)->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** `SUM(x)`. */
	public function sum<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7, T8)->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `AVG(x)`. */
	public function avg<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7, T8)->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Float>;

	/** `MIN(x)`. */
	public function min<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7, T8)->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `MAX(x)`. */
	public function max<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7, T8)->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `ROW_NUMBER()` — which row this is within its window. */
	public function rowNumber():Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** `RANK()`. */
	public function rank():Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** `DENSE_RANK()`. */
	public function denseRank():Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** `LEAD(x, offset)`. */
	public function lead<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7, T8)->TValue, ?offset:Int):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `LAG(x, offset)`. */
	public function lag<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7, T8)->TValue, ?offset:Int):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `FIRST_VALUE(x)` within the window. */
	public function firstValue<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7, T8)->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `LAST_VALUE(x)` within the window. */
	public function lastValue<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7, T8)->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;
}
