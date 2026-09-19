package codequery.queries;

/**
	A table, without its row type. Joining one needs its name and nothing else, and the row type is
	tracked by the `ISelectQueryN` the join answers with — so the generic `IQuery<TTable>` would only
	get in the way here.
**/
interface IQueryTable {
	/** The table, name and schema together, as every statement over it needs both. */
	var Table(default, null):QualifiedTableName;
}
