package codequery;

/**
	The aggregates of a query over 7 rows, as `SelectAggregation` and `Having` see them — C#'s
	`IAggregateSet<T1, T2, T3, T4, T5, T6, T7>`. Each selector takes every row the query has, in the order they were
	joined. As with `IAggregateSet`, nothing here runs: the projection is converted while compiling.
**/
extern class IAggregateSet7<T1, T2, T3, T4, T5, T6, T7> {
	/** `COUNT(*)` — how many rows are in the group. */
	public function count():Aggregate7<T1, T2, T3, T4, T5, T6, T7, Int>;

	/** The grouping key, or one member of it, selected beside the aggregates. */
	public function key<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7)->TValue):TValue;

	/** `COUNT(DISTINCT x)`. */
	public function countDistinct<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7)->TValue):Aggregate7<T1, T2, T3, T4, T5, T6, T7, Int>;

	/** `SUM(x)`. */
	public function sum<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7)->TValue):Aggregate7<T1, T2, T3, T4, T5, T6, T7, TValue>;

	/** `AVG(x)`. */
	public function avg<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7)->TValue):Aggregate7<T1, T2, T3, T4, T5, T6, T7, Float>;

	/** `MIN(x)`. */
	public function min<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7)->TValue):Aggregate7<T1, T2, T3, T4, T5, T6, T7, TValue>;

	/** `MAX(x)`. */
	public function max<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7)->TValue):Aggregate7<T1, T2, T3, T4, T5, T6, T7, TValue>;

	/** `ROW_NUMBER()` — which row this is within its window. */
	public function rowNumber():Aggregate7<T1, T2, T3, T4, T5, T6, T7, Int>;

	/** `RANK()`. */
	public function rank():Aggregate7<T1, T2, T3, T4, T5, T6, T7, Int>;

	/** `DENSE_RANK()`. */
	public function denseRank():Aggregate7<T1, T2, T3, T4, T5, T6, T7, Int>;

	/** `LEAD(x, offset)`. */
	public function lead<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7)->TValue, ?offset:Int):Aggregate7<T1, T2, T3, T4, T5, T6, T7, TValue>;

	/** `LAG(x, offset)`. */
	public function lag<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7)->TValue, ?offset:Int):Aggregate7<T1, T2, T3, T4, T5, T6, T7, TValue>;

	/** `FIRST_VALUE(x)` within the window. */
	public function firstValue<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7)->TValue):Aggregate7<T1, T2, T3, T4, T5, T6, T7, TValue>;

	/** `LAST_VALUE(x)` within the window. */
	public function lastValue<TValue>(selector:(T1, T2, T3, T4, T5, T6, T7)->TValue):Aggregate7<T1, T2, T3, T4, T5, T6, T7, TValue>;
}
