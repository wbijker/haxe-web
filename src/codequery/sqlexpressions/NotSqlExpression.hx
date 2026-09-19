package codequery.sqlexpressions;

/** `NOT (…)`. */
class NotSqlExpression implements ISqlExpression {
	public final Operand:ISqlExpression;

	public function new(operand:ISqlExpression) {
		this.Operand = operand;
	}
}
