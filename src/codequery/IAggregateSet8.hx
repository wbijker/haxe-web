package codequery;

/**
	The aggregates of a query over 8 rows — `IAggregateSet`, with a lambda over every row the query
	has: `a.sum((t, acc) -> t.amount)`. Generated from `IAggregateSet`; see it for what each does.
**/
extern class IAggregateSet8<T1, T2, T3, T4, T5, T6, T7, T8> {
	/** `COUNT(*)` — how many rows are in the group. */
	public function count():Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** `COUNT(DISTINCT x)`. */
	public function countDistinct<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** `COUNT(x)` — the values rather than the rows, so a null is not counted. */
	public function countValues<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** `SUM(x)`. */
	public function sum<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `SUM(DISTINCT x)`. */
	public function sumDistinct<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/**
		The group's key, read beside its aggregates — C#'s `g.Key` after a `GroupBy`. It is the one
		column that may sit beside an aggregate, and it must be one the query grouped by.
	**/
	public function key<TKey>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TKey):TKey;

	/** `AVG(x)`. */
	public function avg<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Float>;

	/** `MIN(x)`. */
	public function min<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `MAX(x)`. */
	public function max<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `ROW_NUMBER()` — which row this is within its window. */
	public function rowNumber():Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** `RANK()` — ties share a rank and leave a gap after it. */
	public function rank():Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** `DENSE_RANK()` — ties share a rank and leave no gap. */
	public function denseRank():Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, Int>;

	/** `LEAD(x, offset)` — the value `offset` rows further on. */
	public function lead<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue, ?offset:Int):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `LAG(x, offset)` — the value `offset` rows back. */
	public function lag<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue, ?offset:Int):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `FIRST_VALUE(x)` within the window. */
	public function firstValue<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;

	/** `LAST_VALUE(x)` within the window. */
	public function lastValue<TValue>(selector:T1->T2->T3->T4->T5->T6->T7->T8->TValue):Aggregate8<T1, T2, T3, T4, T5, T6, T7, T8, TValue>;
}
