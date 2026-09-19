package codequery.sqlexpressions;

/** `CAST(x AS type)`. */
class SqlCastExpression implements ISqlExpression {
	public final Value:ISqlExpression;
	public final Type:SqlType;

	public function new(value:ISqlExpression, type:SqlType) {
		this.Value = value;
		this.Type = type;
	}
}
