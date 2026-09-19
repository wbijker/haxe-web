package codequery.queries;

import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.SelectExpression;

/**
	The runtime half of `ISelectQuery` — everything that is an ordinary method call.

	It exists because a Haxe macro method cannot be reached through an interface: dispatch on an
	interface is a runtime lookup, and a macro has to be resolved while compiling the call. So the
	contract implementations implement is this, and `ISelectQuery` adds the compile-time half on top.
**/
interface ISelectQueryRuntime<T1> {
	/**
		Adds a condition already converted to SQL. `ISelectQuery.Where` is what callers use; this is
		what it compiles down to.
	**/
	function WhereCondition(condition:ISqlExpression):ISelectQuery<T1>;

	/** The statement built so far. */
	function ToExpression():SelectExpression;
}
