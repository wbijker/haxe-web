package codequery.sqlexpressions;

/**
	Sends an expression to the visitor's method for its kind.

	The one place that knows every kind there is. Adding a kind here and to
	`ISqlExpressionVisitor` is what makes every visitor stop compiling until it handles it.
**/
class SqlExpressionWalker {
	public static function Visit<T>(e:ISqlExpression, visitor:ISqlExpressionVisitor<T>):T {
		final column = Std.downcast(cast e, ColumnSqlExpression);
		if (column != null) return visitor.OnColumn(column);

		final all = Std.downcast(cast e, AllColumnsSqlExpression);
		if (all != null) return visitor.OnAllColumns(all);

		final constant = Std.downcast(cast e, ConstSqlExpression);
		if (constant != null) return visitor.OnConst(constant);

		final parameter = Std.downcast(cast e, SqlParameterExpression);
		if (parameter != null) return visitor.OnParameter(parameter);

		final binary = Std.downcast(cast e, BinarySqlExpression);
		if (binary != null) return visitor.OnBinary(binary);

		final negation = Std.downcast(cast e, NotSqlExpression);
		if (negation != null) return visitor.OnNot(negation);

		final within = Std.downcast(cast e, InSqlExpression);
		if (within != null) return visitor.OnIn(within);

		final span = Std.downcast(cast e, BetweenSqlExpression);
		if (span != null) return visitor.OnBetween(span);

		final distinct = Std.downcast(cast e, IsDistinctFromSqlExpression);
		if (distinct != null) return visitor.OnIsDistinctFrom(distinct);

		final branching = Std.downcast(cast e, CaseSqlExpression);
		if (branching != null) return visitor.OnCase(branching);

		final call = Std.downcast(cast e, SqlFunctionExpression);
		if (call != null) return visitor.OnFunction(call);

		final converted = Std.downcast(cast e, SqlCastExpression);
		if (converted != null) return visitor.OnCast(converted);

		final raw = Std.downcast(cast e, RawSqlExpression);
		if (raw != null) return visitor.OnRaw(raw);

		final aggregate = Std.downcast(cast e, AggregateSqlExpression);
		if (aggregate != null) return visitor.OnAggregate(aggregate);

		final projection = Std.downcast(cast e, ProjectionSqlExpression);
		if (projection != null) return visitor.OnProjection(projection);

		final exists = Std.downcast(cast e, ExistsSqlExpression);
		if (exists != null) return visitor.OnExists(exists);

		final scalar = Std.downcast(cast e, ScalarSubquerySqlExpression);
		if (scalar != null) return visitor.OnScalarSubquery(scalar);

		final quantified = Std.downcast(cast e, QuantifiedComparisonSqlExpression);
		if (quantified != null) return visitor.OnQuantified(quantified);

		final windowed = Std.downcast(cast e, WindowFunctionExpression);
		if (windowed != null) return visitor.OnWindowFunction(windowed);

		final ordering = Std.downcast(cast e, OrderByExpression);
		if (ordering != null) return visitor.OnOrderBy(ordering);

		final stringOperation = Std.downcast(cast e, StringOperationExpression);
		if (stringOperation != null) return visitor.OnStringOperation(stringOperation);

		final dateOperation = Std.downcast(cast e, DateOperationSqlExpression);
		if (dateOperation != null) return visitor.OnDateOperation(dateOperation);

		final dateFormat = Std.downcast(cast e, DateFormatSqlExpression);
		if (dateFormat != null) return visitor.OnDateFormat(dateFormat);

		final interval = Std.downcast(cast e, IntervalSqlExpression);
		if (interval != null) return visitor.OnInterval(interval);

		throw 'No visitor case for ${Type.getClassName(Type.getClass(e))}';
	}
}
