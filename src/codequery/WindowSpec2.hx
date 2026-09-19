package codequery;

import codequery.sqlexpressions.NullsOrdering;

/**
	A window over a query of 2 rows being described — `WindowSpec`, with its key lambdas over every
	row the query has. Generated from `WindowSpec`; see it for what each does.
**/
extern class WindowSpec2<T1, T2> {
	/** `PARTITION BY key`. Called again, it adds another term. */
	public function PartitionBy<TKey>(key:T1->T2->TKey):WindowSpec2<T1, T2>;

	/** `ORDER BY key ASC`, within the window. */
	public function OrderBy<TKey>(key:T1->T2->TKey, ?nulls:NullsOrdering):WindowSpec2<T1, T2>;

	/** `ORDER BY key DESC`, within the window. */
	public function OrderByDesc<TKey>(key:T1->T2->TKey, ?nulls:NullsOrdering):WindowSpec2<T1, T2>;

	/** `ROWS BETWEEN start AND end` — which rows of the partition are actually read. */
	public function Rows(start:codequery.sqlexpressions.WindowBound,
		end:codequery.sqlexpressions.WindowBound):WindowSpec2<T1, T2>;

	/** `RANGE BETWEEN start AND end`. */
	public function Range(start:codequery.sqlexpressions.WindowBound,
		end:codequery.sqlexpressions.WindowBound):WindowSpec2<T1, T2>;

	/** `ROWS BETWEEN start AND end` — the same as `Rows`, under the name the C# gives it. */
	public function RowsBetween(start:codequery.sqlexpressions.WindowBound,
		end:codequery.sqlexpressions.WindowBound):WindowSpec2<T1, T2>;

	/** `RANGE BETWEEN start AND end` — the same as `Range`, under the name the C# gives it. */
	public function RangeBetween(start:codequery.sqlexpressions.WindowBound,
		end:codequery.sqlexpressions.WindowBound):WindowSpec2<T1, T2>;
}
