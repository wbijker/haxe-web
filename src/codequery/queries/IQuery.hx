package codequery.queries;

/**
	The entry point for querying and mutating a single table of `TTable` entities.

	Only `From` so far; `Update`, `Delete` and `Insert` follow.
**/
interface IQuery<TTable> extends IQueryTable {
	/** Begins a SELECT over this table: `SELECT … FROM TTable`. */
	function From():ISelectQuery<TTable>;

	/** Begins an UPDATE of this table's rows. */
	function Update():IUpdateQuery<TTable>;

	/** Begins a DELETE from this table. */
	function Delete():IDeleteQuery<TTable>;
}
