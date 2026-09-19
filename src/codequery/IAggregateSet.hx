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
	public function count():Aggregate<Int>;

	/** `COUNT(DISTINCT x)`. */
	public function countDistinct<TValue>(selector:T1->TValue):Aggregate<Int>;

	/** `SUM(x)`. */
	public function sum<TValue>(selector:T1->TValue):Aggregate<TValue>;

	/** `AVG(x)`. */
	public function avg<TValue>(selector:T1->TValue):Aggregate<Float>;

	/** `MIN(x)`. */
	public function min<TValue>(selector:T1->TValue):Aggregate<TValue>;

	/** `MAX(x)`. */
	public function max<TValue>(selector:T1->TValue):Aggregate<TValue>;
}
