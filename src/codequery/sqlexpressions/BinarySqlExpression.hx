package codequery.sqlexpressions;

/** Two operands joined by an operator. */
class BinarySqlExpression implements ISqlExpression {
	public final Left:ISqlExpression;
	public final Operator:SqlBinaryOperator;
	public final Right:ISqlExpression;

	public function new(left:ISqlExpression, op:SqlBinaryOperator, right:ISqlExpression) {
		this.Left = left;
		this.Operator = op;
		this.Right = right;
	}
}
