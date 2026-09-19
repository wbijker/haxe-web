package codequery.queries;

/**
	The entry point for querying and mutating a single table of `TTable` entities.

	Only `From` so far; `Update`, `Delete` and `Insert` follow.
**/
interface IQuery<TTable> {
	/**
		The table, name and schema together. C# reaches this through the concrete `DbTable`; it is
		on the interface here because joining a table needs its name.
	**/
	var Table(default, null):QualifiedTableName;

	/** Begins a SELECT over this table: `SELECT … FROM TTable`. */
	function From():ISelectQuery<TTable>;
}
