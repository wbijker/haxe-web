package codequery.sqlexpressions;

/** `x IN (…)`, over a list of values or over a subquery. */
class InSqlExpression implements ISqlExpression {
	public final Value:ISqlExpression;
	public final Values:Array<ISqlExpression>;
	public final Subquery:Null<SelectExpression>;
	public final Negate:Bool;

	public function new(value:ISqlExpression, values:Array<ISqlExpression>, ?subquery:SelectExpression,
			negate:Bool = false) {
		this.Value = value;
		this.Values = values;
		this.Subquery = subquery;
		this.Negate = negate;
	}
}
