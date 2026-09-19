package codequery.sqlexpressions;

/** `x BETWEEN lower AND upper` — inclusive at both ends, as SQL has it. */
class BetweenSqlExpression implements ISqlExpression {
	public final Value:ISqlExpression;
	public final Lower:ISqlExpression;
	public final Upper:ISqlExpression;
	public final Negate:Bool;

	public function new(value:ISqlExpression, lower:ISqlExpression, upper:ISqlExpression, negate:Bool = false) {
		this.Value = value;
		this.Lower = lower;
		this.Upper = upper;
		this.Negate = negate;
	}
}
