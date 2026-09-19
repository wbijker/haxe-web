package codequery.queries;

import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.ISqlSource;
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
		what it compiles down to, and it takes the converted predicate as a function of the
		statement's sources, since which source a lambda parameter stands for is known only here.
	**/
	function WhereCondition(condition:Array<ISqlSource>->ISqlExpression):ISelectQuery<T1>;

	/** The statement built so far. */
	function ToExpression():SelectExpression;
}
