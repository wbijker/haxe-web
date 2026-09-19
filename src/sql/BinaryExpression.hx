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

	public function describe(indent:String = ""):String {
		final child = indent + "  ";
		return '${indent}BinaryExpression\n'
			+ '${child}operator: ${(op : String)}\n'
			+ '${child}left:\n${left.describe(child + "  ")}\n'
			+ '${child}right:\n${right.describe(child + "  ")}';
	}

	/** Parenthesise a child only when it binds more loosely than we do. */
	function operand(e:SqlExpression):String {
		final nested = Std.downcast(e, BinaryExpression);
		final sql = e.toSql();
		return (nested != null && nested.op.precedence() < op.precedence()) ? '($sql)' : sql;
	}
}
