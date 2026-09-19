package codequery.sqlexpressions;

/** One term of an ORDER BY. */
class OrderByExpression implements ISqlExpression {
	public final Expression:ISqlExpression;
	public final Ascending:Bool;
	public final Nulls:NullsOrdering;

	public function new(expression:ISqlExpression, ascending:Bool, nulls:NullsOrdering = Default) {
		this.Expression = expression;
		this.Ascending = ascending;
		this.Nulls = nulls;
	}
}
