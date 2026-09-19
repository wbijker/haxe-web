package codequery.sqlexpressions;

/**
	Reads an expression written over a reduced row back onto the sources it stands for.

	After a `Reduce`, a lambda's first parameter is the row the reduce built and the rest are the
	sources joined since. A column reached through that row was emitted, while compiling, as a
	column of parameter 0 named for its path — `x.u.name` is `u_name` — and only the statement knows
	what the reduce projected under that name. This puts the two together: such a column becomes
	the expression it was projected from, and a column of a later parameter is moved past the
	sources the reduced row folded up. Everything else is rebuilt around its resolved children.
**/
class ProjectionResolver implements ISqlExpressionVisitor<ISqlExpression> {
	final projected:Map<String, ISqlExpression>;
	final reduced:Int;

	function new(projected:Map<String, ISqlExpression>, reduced:Int) {
		this.projected = projected;
		this.reduced = reduced;
	}

	/** `e`, read against a statement whose first `reduced` sources are carried by one row. */
	public static function Resolve(e:ISqlExpression, projected:Map<String, ISqlExpression>, reduced:Int):ISqlExpression {
		if (e == null || reduced == 0) {
			return e;
		}
		return new ProjectionResolver(projected, reduced).Visit(e);
	}

	function Visit(e:ISqlExpression):ISqlExpression {
		return e == null ? null : SqlExpressionWalker.Visit(e, this);
	}

	function Each(list:Array<ISqlExpression>):Array<ISqlExpression> {
		return list.map(Visit);
	}

	/** The parameter a source is, at this statement's own depth, or null for any other source. */
	function Parameter(source:ISqlSource):Null<ParameterSqlSource> {
		final parameter = Std.downcast(cast source, ParameterSqlSource);
		return parameter != null && parameter.Scope == 0 ? parameter : null;
	}

	/** A later parameter is numbered after the sources the reduced row stands for. */
	function Moved(parameter:ParameterSqlSource):ParameterSqlSource {
		return ParameterSqlSource.At(reduced + parameter.Index - 1);
	}

	public function OnColumn(e:ColumnSqlExpression):ISqlExpression {
		final parameter = Parameter(e.Source);
		if (parameter == null) {
			return e;
		}
		if (parameter.Index == 0) {
			final known = projected.get(e.ColumnName);
			return known != null ? known : e;
		}
		return new ColumnSqlExpression(Moved(parameter), e.ColumnName, e.ColumnType);
	}

	public function OnAllColumns(e:AllColumnsSqlExpression):ISqlExpression {
		final parameter = Parameter(e.Source);
		return parameter == null || parameter.Index == 0 ? e : new AllColumnsSqlExpression(Moved(parameter));
	}

	public function OnConst(e:ConstSqlExpression):ISqlExpression {
		return e;
	}

	public function OnParameter(e:SqlParameterExpression):ISqlExpression {
		return e;
	}

	public function OnBinary(e:BinarySqlExpression):ISqlExpression {
		return new BinarySqlExpression(Visit(e.Left), e.Operator, Visit(e.Right));
	}

	public function OnNot(e:NotSqlExpression):ISqlExpression {
		return new NotSqlExpression(Visit(e.Operand));
	}

	public function OnIn(e:InSqlExpression):ISqlExpression {
		return new InSqlExpression(Visit(e.Value), Each(e.Values), e.Subquery, e.Negate);
	}

	public function OnBetween(e:BetweenSqlExpression):ISqlExpression {
		return new BetweenSqlExpression(Visit(e.Value), Visit(e.Lower), Visit(e.Upper), e.Negate);
	}

	public function OnIsDistinctFrom(e:IsDistinctFromSqlExpression):ISqlExpression {
		return new IsDistinctFromSqlExpression(Visit(e.Left), Visit(e.Right), e.Negate);
	}

	public function OnCase(e:CaseSqlExpression):ISqlExpression {
		return new CaseSqlExpression([for (b in e.Branches) new CaseBranch(Visit(b.When), Visit(b.Then))],
			Visit(e.Otherwise));
	}

	public function OnFunction(e:SqlFunctionExpression):ISqlExpression {
		return new SqlFunctionExpression(e.Name, Each(e.Arguments), e.Infix);
	}

	public function OnCast(e:SqlCastExpression):ISqlExpression {
		return new SqlCastExpression(Visit(e.Value), e.Type);
	}

	public function OnRaw(e:RawSqlExpression):ISqlExpression {
		return e;
	}

	public function OnAggregate(e:AggregateSqlExpression):ISqlExpression {
		return new AggregateSqlExpression(e.Type, Visit(e.Argument), e.Distinct, e.Window, e.Over, Visit(e.Filter));
	}

	public function OnProjection(e:ProjectionSqlExpression):ISqlExpression {
		return new ProjectionSqlExpression([
			for (m in e.Members) new ProjectionMember(m.Name, Visit(m.Expression), m.Path)
		]);
	}

	public function OnExists(e:ExistsSqlExpression):ISqlExpression {
		return e;
	}

	public function OnScalarSubquery(e:ScalarSubquerySqlExpression):ISqlExpression {
		return e;
	}

	public function OnQuantified(e:QuantifiedComparisonSqlExpression):ISqlExpression {
		return new QuantifiedComparisonSqlExpression(Visit(e.Value), e.Operator, e.Quantifier, e.Subquery);
	}

	public function OnWindowFunction(e:WindowFunctionExpression):ISqlExpression {
		return new WindowFunctionExpression(e.Function, Each(e.Arguments), e.Window, e.Over);
	}

	public function OnDistinct(e:DistinctSqlExpression):ISqlExpression {
		return new DistinctSqlExpression(Visit(e.Value));
	}

	public function OnObjectConst(e:ObjectConstSqlExpression):ISqlExpression {
		return new ObjectConstSqlExpression(Each(e.Fields), e.TypeName);
	}

	public function OnStringOperation(e:StringOperationExpression):ISqlExpression {
		return new StringOperationExpression(Visit(e.Operand), e.OperationType, Visit(e.Pattern));
	}

	public function OnDateOperation(e:DateOperationSqlExpression):ISqlExpression {
		return new DateOperationSqlExpression(e.Operation, e.Part, Visit(e.Value), Visit(e.Other));
	}

	public function OnDateFormat(e:DateFormatSqlExpression):ISqlExpression {
		return new DateFormatSqlExpression(Visit(e.Value), e.Parts);
	}

	/** An interval carries no column, so there is nothing in it to resolve. */
	public function OnInterval(e:IntervalSqlExpression):ISqlExpression {
		return e;
	}

	public function OnOrderBy(e:OrderByExpression):ISqlExpression {
		return new OrderByExpression(Visit(e.Expression), e.Ascending, e.Nulls);
	}
}
