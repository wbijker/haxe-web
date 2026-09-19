package codequery.sqlexpressions;

/**
	`DISTINCT x` — the keyword in front of a projected member, which is where C#'s
	`DbAggregation.Distinct(x)` puts it. It says what `SELECT DISTINCT` says; which spelling reads
	better depends on whether the statement or the column is the thing being looked at.
**/
class DistinctSqlExpression implements ISqlExpression {
	public final Value:ISqlExpression;

	public function new(value:ISqlExpression) {
		this.Value = value;
	}
}
