package sql;

/** Two operands joined by an operator, e.g. `d.Id > 10`. */
class BinaryExpression extends SqlExpression {
	public final left:SqlExpression;
	public final op:SqlBinaryOperator;
	public final right:SqlExpression;

	public function new(left:SqlExpression, op:SqlBinaryOperator, right:SqlExpression) {
		super();
		this.left = left;
		this.op = op;
		this.right = right;
	}

	public function toSql():String {
		return '${operand(left)} ${(op : String)} ${operand(right)}';
	}

	/** Parenthesise a child only when it binds more loosely than we do. */
	function operand(e:SqlExpression):String {
		final nested = Std.downcast(e, BinaryExpression);
		final sql = e.toSql();
		return (nested != null && nested.op.precedence() < op.precedence()) ? '($sql)' : sql;
	}
}
