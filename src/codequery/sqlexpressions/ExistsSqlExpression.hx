package codequery.sqlexpressions;

/** `EXISTS (…)`, or `NOT EXISTS (…)`. */
class ExistsSqlExpression implements ISqlExpression {
	public final Subquery:SelectExpression;
	public final Negate:Bool;

	public function new(subquery:SelectExpression, negate:Bool = false) {
		// EXISTS asks whether a row is there, not what is on it, so naming every column would be
		// noise in the one place it buys nothing: the columns are never read.
		subquery.Selection = null;
		this.Subquery = subquery;
		this.Negate = negate;
	}
}
