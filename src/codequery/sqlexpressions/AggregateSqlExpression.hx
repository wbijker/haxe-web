package codequery.sqlexpressions;

/** The aggregate functions. Only the one counting rows is reached so far. */
enum AggregateFunction {
	CountRows;
}

/** An aggregate over the statement's rows. */
class AggregateSqlExpression implements ISqlExpression {
	public final Function:AggregateFunction;

	public function new(fn:AggregateFunction) {
		this.Function = fn;
	}

	/** `COUNT(*)`. */
	public static function Count():AggregateSqlExpression {
		return new AggregateSqlExpression(CountRows);
	}
}
