package codequery;

/**
	Window aggregates — an aggregate read beside the ordinary columns of a row, which is the only
	place an aggregate may appear without a GROUP BY:

	```haxe
	.Select(t -> {running: DbAggregation.sum(t.amount).filter(t.amount > 0).over(null, t.orderDate)})
	// SUM(amount) FILTER (WHERE amount > 0) OVER (ORDER BY order_date)
	```

	Every aggregate written here is finished with `over(…)`. There is no other terminator, and that
	is SQL's rule rather than this library's: an aggregate takes many rows and yields one, so a
	select holding one may not also hold a column of a single row — unless the aggregate is computed
	per row, which is what a window is.

	The other two shapes an aggregate can have are asked for elsewhere, because they are different
	statements rather than different spellings: `SelectAggregation(a -> …)` for a select of nothing
	but aggregates, and `GroupBy(…).SelectAggregation(g -> …)` for one row per group.

	Nothing here runs: the projection it appears in is read while compiling and becomes an
	`AggregateSqlExpression`.
**/
extern class DbAggregation {
	/** `SUM(x)`. */
	public static function sum<T>(value:T):AggBuilder<T>;

	/** `AVG(x)`. */
	public static function avg<T>(value:T):AggBuilder<Float>;

	/** `MIN(x)`. */
	public static function min<T>(value:T):AggBuilder<T>;

	/** `MAX(x)`. */
	public static function max<T>(value:T):AggBuilder<T>;

	/** `COUNT(*)` — the rows. */
	public static function count():AggBuilder<Int>;

	/** `COUNT(x)` — the values, so a null is not counted. */
	public static function countValues<T>(value:T):AggBuilder<Int>;

	/**
		`DISTINCT` in front of the projected member — not an aggregate of its own, but the keyword
		form of what `.Distinct()` on the query says.
	**/
	public static function distinct<T>(value:T):T;
}
