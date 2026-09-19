package codequery;

import codequery.sqlexpressions.NullsOrdering;

/**
	A window over a query of 8 rows being described — `WindowSpec`, with its key lambdas over every
	row the query has. Generated from `WindowSpec`; see it for what each does.
**/
extern class WindowSpec8<T1, T2, T3, T4, T5, T6, T7, T8> {
	/** `PARTITION BY key`. Called again, it adds another term. */
	public function PartitionBy<TKey>(key:T1->T2->T3->T4->T5->T6->T7->T8->TKey):WindowSpec8<T1, T2, T3, T4, T5, T6, T7, T8>;

	/** `ORDER BY key ASC`, within the window. */
	public function OrderBy<TKey>(key:T1->T2->T3->T4->T5->T6->T7->T8->TKey, ?nulls:NullsOrdering):WindowSpec8<T1, T2, T3, T4, T5, T6, T7, T8>;

	/** `ORDER BY key DESC`, within the window. */
	public function OrderByDesc<TKey>(key:T1->T2->T3->T4->T5->T6->T7->T8->TKey, ?nulls:NullsOrdering):WindowSpec8<T1, T2, T3, T4, T5, T6, T7, T8>;

	/** `ROWS BETWEEN start AND end` — which rows of the partition are actually read. */
	public function Rows(start:codequery.sqlexpressions.WindowBound,
		end:codequery.sqlexpressions.WindowBound):WindowSpec8<T1, T2, T3, T4, T5, T6, T7, T8>;

	/** `RANGE BETWEEN start AND end`. */
	public function Range(start:codequery.sqlexpressions.WindowBound,
		end:codequery.sqlexpressions.WindowBound):WindowSpec8<T1, T2, T3, T4, T5, T6, T7, T8>;

	/** `ROWS BETWEEN start AND end` — the same as `Rows`, under the name the C# gives it. */
	public function RowsBetween(start:codequery.sqlexpressions.WindowBound,
		end:codequery.sqlexpressions.WindowBound):WindowSpec8<T1, T2, T3, T4, T5, T6, T7, T8>;

	/** `RANGE BETWEEN start AND end` — the same as `Range`, under the name the C# gives it. */
	public function RangeBetween(start:codequery.sqlexpressions.WindowBound,
		end:codequery.sqlexpressions.WindowBound):WindowSpec8<T1, T2, T3, T4, T5, T6, T7, T8>;
}
