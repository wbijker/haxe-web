package codequery.sqlexpressions;

/** A constant in a statement. */
class ConstSqlExpression implements ISqlExpression {
	public final Value:SqlConstValue;

	public function new(value:SqlConstValue) {
		this.Value = value;
	}
}
