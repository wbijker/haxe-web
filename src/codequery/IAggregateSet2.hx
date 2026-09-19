package codequery;

/**
	The aggregates of a query over 2 rows — `IAggregateSet`, with a lambda over every row the query
	has: `a.sum((t, acc) -> t.amount)`. Generated from `IAggregateSet`; see it for what each does.
**/
extern class IAggregateSet2<T1, T2> {
	/** `COUNT(*)` — how many rows are in the group. */
	public function count():Aggregate2<T1, T2, Int>;

	/** `COUNT(DISTINCT x)`. */
	public function countDistinct<TValue>(selector:T1->T2->TValue):Aggregate2<T1, T2, Int>;

	/** `COUNT(x)` — the values rather than the rows, so a null is not counted. */
	public function countValues<TValue>(selector:T1->T2->TValue):Aggregate2<T1, T2, Int>;

	/** `SUM(x)`. */
	public function sum<TValue>(selector:T1->T2->TValue):Aggregate2<T1, T2, TValue>;

	/** `SUM(DISTINCT x)`. */
	public function sumDistinct<TValue>(selector:T1->T2->TValue):Aggregate2<T1, T2, TValue>;

	/**
		The group's key, read beside its aggregates — C#'s `g.Key` after a `GroupBy`. It is the one
		column that may sit beside an aggregate, and it must be one the query grouped by.
	**/
	public function key<TKey>(selector:T1->T2->TKey):TKey;

	/** `AVG(x)`. */
	public function avg<TValue>(selector:T1->T2->TValue):Aggregate2<T1, T2, Float>;

	/** `MIN(x)`. */
	public function min<TValue>(selector:T1->T2->TValue):Aggregate2<T1, T2, TValue>;

	/** `MAX(x)`. */
	public function max<TValue>(selector:T1->T2->TValue):Aggregate2<T1, T2, TValue>;

	/** `ROW_NUMBER()` — which row this is within its window. */
	public function rowNumber():Aggregate2<T1, T2, Int>;

	/** `RANK()` — ties share a rank and leave a gap after it. */
	public function rank():Aggregate2<T1, T2, Int>;

	/** `DENSE_RANK()` — ties share a rank and leave no gap. */
	public function denseRank():Aggregate2<T1, T2, Int>;

	/** `LEAD(x, offset)` — the value `offset` rows further on. */
	public function lead<TValue>(selector:T1->T2->TValue, ?offset:Int):Aggregate2<T1, T2, TValue>;

	/** `LAG(x, offset)` — the value `offset` rows back. */
	public function lag<TValue>(selector:T1->T2->TValue, ?offset:Int):Aggregate2<T1, T2, TValue>;

	/** `FIRST_VALUE(x)` within the window. */
	public function firstValue<TValue>(selector:T1->T2->TValue):Aggregate2<T1, T2, TValue>;

	/** `LAST_VALUE(x)` within the window. */
	public function lastValue<TValue>(selector:T1->T2->TValue):Aggregate2<T1, T2, TValue>;
}
