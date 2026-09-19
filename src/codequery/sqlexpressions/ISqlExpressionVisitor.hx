package codequery.sqlexpressions;

/**
	What to do with each kind of expression.

	The driver used a chain of downcasts, which was fine while there were three kinds and is not at
	twenty: every kind cost a test, the order of the tests mattered, and a kind nobody handled was
	found at runtime rather than when it was added. A visitor is checked instead — add a kind to
	`SqlExpressionWalker` and every visitor stops compiling until it says what to do with it.
**/
interface ISqlExpressionVisitor<T> {
	function OnColumn(e:ColumnSqlExpression):T;
	function OnAllColumns(e:AllColumnsSqlExpression):T;
	function OnConst(e:ConstSqlExpression):T;
	function OnParameter(e:SqlParameterExpression):T;
	function OnBinary(e:BinarySqlExpression):T;
	function OnNot(e:NotSqlExpression):T;
	function OnIn(e:InSqlExpression):T;
	function OnBetween(e:BetweenSqlExpression):T;
	function OnIsDistinctFrom(e:IsDistinctFromSqlExpression):T;
	function OnCase(e:CaseSqlExpression):T;
	function OnFunction(e:SqlFunctionExpression):T;
	function OnCast(e:SqlCastExpression):T;
	function OnRaw(e:RawSqlExpression):T;
	function OnAggregate(e:AggregateSqlExpression):T;
	function OnProjection(e:ProjectionSqlExpression):T;
	function OnExists(e:ExistsSqlExpression):T;
	function OnScalarSubquery(e:ScalarSubquerySqlExpression):T;
	function OnQuantified(e:QuantifiedComparisonSqlExpression):T;
	function OnWindowFunction(e:WindowFunctionExpression):T;
	function OnOrderBy(e:OrderByExpression):T;
	function OnObjectConst(e:ObjectConstSqlExpression):T;
	function OnDistinct(e:DistinctSqlExpression):T;
}
