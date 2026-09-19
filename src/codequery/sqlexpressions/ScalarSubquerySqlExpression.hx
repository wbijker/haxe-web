package codequery.sqlexpressions;

/** A subquery standing where a value does — one row of one column. */
class ScalarSubquerySqlExpression implements ISqlExpression {
	public final Subquery:SelectExpression;

	/** Whether it may name the rows of the statement it sits in. */
	public final Correlated:Bool;

	public function new(subquery:SelectExpression, correlated:Bool) {
		this.Subquery = subquery;
		this.Correlated = correlated;
	}
}
