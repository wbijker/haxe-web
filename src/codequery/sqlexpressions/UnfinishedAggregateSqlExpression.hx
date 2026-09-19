package codequery.sqlexpressions;

/**
	An aggregate written with `DbAggregation` beside a row's own columns, and never finished with
	`over(…)`.

	SQL takes many rows and yields one, so an aggregate can only sit beside ordinary columns if it is
	computed per row — which is what a window is. C# refuses this while converting the lambda; here
	the lambda is converted while compiling, and a compile error is not something a test can catch,
	so the refusal is carried to where the statement is rendered and raised there instead.
**/
class UnfinishedAggregateSqlExpression extends AggregateSqlExpression {
	public static final Message = "An aggregate written with DbAggregation is finished with Over(...), which is the only "
		+ "way SQL can read one beside ordinary columns. For a select of nothing but aggregates "
		+ "use SelectAggregation(a -> …), and for one per group use GroupBy(…).SelectAggregation(g -> …).";

	public function new(aggregate:AggregateSqlExpression) {
		super(aggregate.Type, aggregate.Argument, aggregate.Distinct, null, null, aggregate.Filter);
	}
}
