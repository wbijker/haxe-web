package codequery.queries;

import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.JoinType;
import codequery.sqlexpressions.NullsOrdering;
import codequery.sqlexpressions.SelectExpression;

/**
	The runtime half of `ISelectQuery` — everything that is an ordinary method call.

	It exists because a Haxe macro method cannot be reached through an interface: dispatch on an
	interface is a runtime lookup, and a macro has to be resolved while compiling the call. So the
	contract implementations implement is this, and `ISelectQuery` adds the compile-time half on top.

	A clause whose C# signature takes an `Expression` appears here in converted form, taking the
	`ISqlExpression` the macro produced. The rest — `Limit`, `Offset` and the like — take ordinary
	values in C# too, and so keep their own names and are called directly.
**/
interface ISelectQueryRuntime<T1> {
	/** What `ISelectQuery.Where` compiles down to. */
	function WhereCondition(condition:ISqlExpression):ISelectQuery<T1>;

	/** What `ISelectQuery.Distinct()` compiles down to. */
	function DistinctRows():ISelectQuery<T1>;

	/** What `ISelectQuery.Distinct(on)` compiles down to. */
	function DistinctOnKey(key:ISqlExpression):ISelectQuery<T1>;

	/** What the `OrderBy` family compiles down to. */
	function OrderByKey(key:ISqlExpression, ascending:Bool, nulls:NullsOrdering):ISelectQuery<T1>;

	/** What the join family compiles down to when the source is a table. */
	function JoinTable<T2>(type:JoinType, table:IQuery<T2>, on:Null<ISqlExpression>):ISelectQuery2<T1, T2>;

	/** What the join family compiles down to when the source is another query. */
	function JoinQuery<T2>(type:JoinType, source:ISelectQuery<T2>, on:Null<ISqlExpression>):ISelectQuery2<T1, T2>;

	/** At most `count` rows. */
	function Limit(count:Int):ISelectQuery<T1>;

	/** Skips `count` rows. */
	function Offset(count:Int):ISelectQuery<T1>;

	/** Keeps the rows tying with the last one the limit allows. */
	function WithTies():ISelectQuery<T1>;

	/** Reads the limit as a percentage of the rows rather than a count. */
	function Percent():ISelectQuery<T1>;

	/** The statement built so far. */
	function ToExpression():SelectExpression;

	/**
		The statement that counts this one's rows — what `Count` would run.

		Not in the C# API, where counting only ever runs; it is separated out here because rendering
		is all this port can do until a driver can execute.
	**/
	function CountExpression():SelectExpression;

	/** How many rows the query has. Runs the query, so it needs a connection to run it against. */
	function Count():Int;
}
