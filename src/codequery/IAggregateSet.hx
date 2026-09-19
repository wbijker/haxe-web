package codequery;

/**
	The aggregates of a query's rows, as `SelectAggregation` sees them:

	```haxe
	.SelectAggregation(a -> {rows: a.count(), biggest: a.max(r -> r.quantity)})
	```

	Like `Aggregate`, nothing here runs — the projection is converted while compiling. It is here so
	the projection type-checks and an editor can complete inside it.
**/
extern class IAggregateSet<T1> {
	/** `COUNT(*)` — how many rows are in the group. */
	public function count():Aggregate<T1, Int>;

	/**
		The grouping key, or one member of it — `a.key(r -> r.unitId)` — selected beside the
		aggregates. C#'s `g.Key`; here the key is named again, since a query's row types are all a
		macro can read.
	**/
	public function key<TValue>(selector:T1->TValue):TValue;

	/** `COUNT(DISTINCT x)`. */
	public function countDistinct<TValue>(selector:T1->TValue):Aggregate<T1, Int>;

	/** `SUM(x)`. */
	public function sum<TValue>(selector:T1->TValue):Aggregate<T1, TValue>;

	/** `AVG(x)`. */
	public function avg<TValue>(selector:T1->TValue):Aggregate<T1, Float>;

	/** `MIN(x)`. */
	public function min<TValue>(selector:T1->TValue):Aggregate<T1, TValue>;

	/** `MAX(x)`. */
	public function max<TValue>(selector:T1->TValue):Aggregate<T1, TValue>;

	/** `ROW_NUMBER()` — which row this is within its window. */
	public function rowNumber():Aggregate<T1, Int>;

	/** `RANK()` — ties share a rank and leave a gap after it. */
	public function rank():Aggregate<T1, Int>;

	/** `DENSE_RANK()` — ties share a rank and leave no gap. */
	public function denseRank():Aggregate<T1, Int>;

	/** `LEAD(x, offset)` — the value `offset` rows further on. */
	public function lead<TValue>(selector:T1->TValue, ?offset:Int):Aggregate<T1, TValue>;

	/** `LAG(x, offset)` — the value `offset` rows back. */
	public function lag<TValue>(selector:T1->TValue, ?offset:Int):Aggregate<T1, TValue>;

	/** `FIRST_VALUE(x)` within the window. */
	public function firstValue<TValue>(selector:T1->TValue):Aggregate<T1, TValue>;

	/** `LAST_VALUE(x)` within the window. */
	public function lastValue<TValue>(selector:T1->TValue):Aggregate<T1, TValue>;
}
