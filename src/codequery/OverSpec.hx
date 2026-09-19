package codequery;

import codequery.sqlexpressions.NullsOrdering;
import codequery.sqlexpressions.WindowBound;

/**
	`OVER (…)` written out where an aggregate or a window function is used:

	```haxe
	Window.rowNumber(w -> w.PartitionBy(r.tripNumber).OrderByDesc(r.timestamp))
	```

	The keys are the row's own columns, since the row is in scope where this is written — unlike
	`WindowSpec`, which describes a window on the query and so takes lambdas over the row. Nothing
	here runs: the chain is read while compiling and becomes a `WindowDefinition`.
**/
extern class OverSpec {
	/** `PARTITION BY key, …`. Called again, it adds to the keys rather than replacing them. */
	public function PartitionBy(keys:haxe.extern.Rest<Dynamic>):OverSpec;

	/** `ORDER BY key ASC`, within the window. Each term is its own call. */
	public function OrderBy(key:Dynamic, ?nulls:NullsOrdering):OverSpec;

	/** `ORDER BY key DESC`, within the window. */
	public function OrderByDesc(key:Dynamic, ?nulls:NullsOrdering):OverSpec;

	/** `ROWS BETWEEN start AND end` — which rows of the partition are actually read. */
	public function RowsBetween(start:WindowBound, end:WindowBound):OverSpec;

	/** `RANGE BETWEEN start AND end`. */
	public function RangeBetween(start:WindowBound, end:WindowBound):OverSpec;
}
