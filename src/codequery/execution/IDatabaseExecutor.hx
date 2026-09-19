package codequery.execution;

/**
	Something that can run a statement against a database.

	Nothing here implements it: that takes a connection and a wire protocol, which is a driver's
	job and not this port's. It is the seam a driver plugs into — everything up to it is done, so
	what a Postgres or SQL Server driver has to supply is these two methods and nothing else.
**/
interface IDatabaseExecutor {
	/** Runs a statement that answers with rows. */
	function Query(statement:Statement):Array<Map<String, Dynamic>>;

	/** Runs a statement that answers with a count of the rows it changed. */
	function NonQuery(statement:Statement):Int;
}
