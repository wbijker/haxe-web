package codequery.queries;

import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.NullsOrdering;
import codequery.sqlexpressions.SelectExpression;

/** The runtime half of `ISelectQuery2`. See `ISelectQueryRuntime` for why it is split this way. */
interface ISelectQueryRuntime2<T1, T2> {
	function WhereCondition(condition:ISqlExpression):ISelectQuery2<T1, T2>;
	function DistinctRows():ISelectQuery2<T1, T2>;
	function DistinctOnKey(key:ISqlExpression):ISelectQuery2<T1, T2>;
	function OrderByKey(key:ISqlExpression, ascending:Bool, nulls:NullsOrdering):ISelectQuery2<T1, T2>;
	function Limit(count:Int):ISelectQuery2<T1, T2>;
	function Offset(count:Int):ISelectQuery2<T1, T2>;
	function WithTies():ISelectQuery2<T1, T2>;
	function Percent():ISelectQuery2<T1, T2>;
	function ToExpression():SelectExpression;
	function CountExpression():SelectExpression;
	function Count():Int;
}
