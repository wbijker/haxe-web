package codequery.sqlexpressions;

/**
	An aggregate over a statement's rows, or over a window of them.

	`Window` is what makes it windowed: with one it reads `… OVER w`, and the window is defined once
	on the statement rather than repeated at every aggregate naming it.
**/
class AggregateSqlExpression implements ISqlExpression {
	public final Type:AggregateType;
	public final Argument:Null<ISqlExpression>;
	public final Distinct:Bool;
	public final Window:Null<NamedWindowSqlSource>;

	public function new(type:AggregateType, ?argument:ISqlExpression, distinct:Bool = false, ?window:NamedWindowSqlSource) {
		this.Type = type;
		this.Argument = argument;
		this.Distinct = distinct;
		this.Window = window;
	}

	/** `COUNT(*)`. */
	public static function Count():AggregateSqlExpression {
		return new AggregateSqlExpression(AggregateType.Count);
	}

	/** The same aggregate, read over a window. */
	public function Over(window:NamedWindowSqlSource):AggregateSqlExpression {
		return new AggregateSqlExpression(Type, Argument, Distinct, window);
	}
}
