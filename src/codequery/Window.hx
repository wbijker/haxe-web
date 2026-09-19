package codequery;

/**
	The window functions, written beside a row's own columns with the window they read over:

	```haxe
	.Select(b -> {authorId: b.authorId, rn: Window.rowNumber(w -> w.PartitionBy(b.authorId).OrderByDesc(b.revenue))})
	```

	Nothing here runs: the projection is read while compiling and each becomes a
	`WindowFunctionExpression`.
**/
extern class Window {
	/** `ROW_NUMBER()` — which row this is within its window. */
	public static function rowNumber(over:OverSpec->OverSpec):Int;

	/** `RANK()` — ties share a rank and leave a gap after it. */
	public static function rank(over:OverSpec->OverSpec):Int;

	/** `DENSE_RANK()` — ties share a rank and leave no gap. */
	public static function denseRank(over:OverSpec->OverSpec):Int;

	/** `NTILE(n)` — which of `n` equal buckets the row falls in. */
	public static function ntile(buckets:Int, over:OverSpec->OverSpec):Int;

	/** `LAG(x, offset)` — the value `offset` rows back. */
	public static function lag<T>(value:T, offset:Int, over:OverSpec->OverSpec):T;

	/** `LEAD(x, offset)` — the value `offset` rows further on. */
	public static function lead<T>(value:T, offset:Int, over:OverSpec->OverSpec):T;

	/** `FIRST_VALUE(x)` within the window. */
	public static function firstValue<T>(value:T, over:OverSpec->OverSpec):T;

	/** `LAST_VALUE(x)` within the window. */
	public static function lastValue<T>(value:T, over:OverSpec->OverSpec):T;

	/** `NTH_VALUE(x, n)` — the value of the n-th row of the window. */
	public static function nthValue<T>(value:T, n:Int, over:OverSpec->OverSpec):T;

	/** `PERCENT_RANK()` — the rank as a fraction of the window. */
	public static function percentRank(over:OverSpec->OverSpec):Float;

	/** `CUME_DIST()` — how much of the window is at or before this row. */
	public static function cumeDist(over:OverSpec->OverSpec):Float;
}
