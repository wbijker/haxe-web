package codequery;

import codequery.sqlexpressions.NullsOrdering;

/**
	A window being described:

	```haxe
	.Window(w -> w.PartitionBy(a -> a.deliveryId).OrderBy(a -> a.id))
	```

	Nothing here runs either — the chain is read while compiling and becomes a
	`NamedWindowSqlSource` on the statement.
**/
extern class WindowSpec<T1> {
	/** `PARTITION BY key`. Called again, it adds another term. */
	public function PartitionBy<TKey>(key:T1->TKey):WindowSpec<T1>;

	/** `ORDER BY key ASC`, within the window. */
	public function OrderBy<TKey>(key:T1->TKey, ?nulls:NullsOrdering):WindowSpec<T1>;

	/** `ORDER BY key DESC`, within the window. */
	public function OrderByDesc<TKey>(key:T1->TKey, ?nulls:NullsOrdering):WindowSpec<T1>;

	/** `ROWS BETWEEN start AND end` — which rows of the partition are actually read. */
	public function Rows(start:codequery.sqlexpressions.WindowBound,
		end:codequery.sqlexpressions.WindowBound):WindowSpec<T1>;

	/** `RANGE BETWEEN start AND end`. */
	public function Range(start:codequery.sqlexpressions.WindowBound,
		end:codequery.sqlexpressions.WindowBound):WindowSpec<T1>;
}
