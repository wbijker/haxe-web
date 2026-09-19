package codequery.sqlexpressions;

/**
	`x IS DISTINCT FROM y` — the comparison that treats two nulls as equal and one null as
	different, where `=` would answer unknown to both.
**/
class IsDistinctFromSqlExpression implements ISqlExpression {
	public final Left:ISqlExpression;
	public final Right:ISqlExpression;
	public final Negate:Bool;

	public function new(left:ISqlExpression, right:ISqlExpression, negate:Bool = false) {
		this.Left = left;
		this.Right = right;
		this.Negate = negate;
	}
}
