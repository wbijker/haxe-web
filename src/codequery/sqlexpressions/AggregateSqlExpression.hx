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

	/** A window written out here rather than named on the statement. */
	public final Over:Null<WindowDefinition>;

	/** `FILTER (WHERE …)` — which rows the aggregate counts, without narrowing the query itself. */
	public final Filter:Null<ISqlExpression>;

	public function new(type:AggregateType, ?argument:ISqlExpression, distinct:Bool = false,
			?window:NamedWindowSqlSource, ?over:WindowDefinition, ?filter:ISqlExpression) {
		this.Type = type;
		this.Argument = argument;
		this.Distinct = distinct;
		this.Window = window;
		this.Over = over;
		this.Filter = filter;
	}

	/** `COUNT(*)`. */
	public static function Count():AggregateSqlExpression {
		return new AggregateSqlExpression(AggregateType.Count);
	}

	/** The same aggregate, read over a window the statement named. */
	public function OverWindow(window:NamedWindowSqlSource):AggregateSqlExpression {
		return new AggregateSqlExpression(Type, Argument, Distinct, window, null, Filter);
	}

	/** The same aggregate, read over a window written out here. */
	public function OverDefinition(over:WindowDefinition):AggregateSqlExpression {
		return new AggregateSqlExpression(Type, Argument, Distinct, null, over, Filter);
	}

	/** The same aggregate, counting only the rows the condition holds for. */
	public function Filtered(filter:ISqlExpression):AggregateSqlExpression {
		return new AggregateSqlExpression(Type, Argument, Distinct, Window, Over, filter);
	}

	/** The same aggregate, over a framed window. */
	public function Framed(frame:WindowFrame):AggregateSqlExpression {
		if (Over == null) {
			throw "A frame belongs to a window written out with overRows, not to a named one";
		}
		return new AggregateSqlExpression(Type, Argument, Distinct, null,
			new WindowDefinition(Over.PartitionBy, Over.OrderBy, frame), Filter);
	}

	/** The same aggregate, over distinct values. */
	public function Distinctly():AggregateSqlExpression {
		return new AggregateSqlExpression(Type, Argument, true, Window, Over, Filter);
	}
}
