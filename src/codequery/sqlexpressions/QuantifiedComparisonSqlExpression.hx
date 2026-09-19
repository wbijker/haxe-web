package codequery.sqlexpressions;

/** `x > ANY (…)`, `x = ALL (…)`. */
class QuantifiedComparisonSqlExpression implements ISqlExpression {
	public final Value:ISqlExpression;
	public final Operator:SqlBinaryOperator;
	public final Quantifier:Quantifier;
	public final Subquery:SelectExpression;

	public function new(value:ISqlExpression, op:SqlBinaryOperator, quantifier:Quantifier, subquery:SelectExpression) {
		this.Value = value;
		this.Operator = op;
		this.Quantifier = quantifier;
		this.Subquery = subquery;
	}
}
