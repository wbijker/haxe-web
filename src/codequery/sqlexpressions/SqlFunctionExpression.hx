package codequery.sqlexpressions;

/**
	A call of a SQL function — `UPPER(x)`, `COALESCE(a, b)` and the rest.

	The name is rendered as it stands, so it is the dialect's own spelling; a driver that spells one
	differently is where that would be translated.
**/
class SqlFunctionExpression implements ISqlExpression {
	public final Name:String;
	public final Arguments:Array<ISqlExpression>;

	/** `a || b` rather than `f(a, b)` — a function written between its arguments. */
	public final Infix:Bool;

	/**
		`WITHIN GROUP (ORDER BY …)` — the ordering an ordered-set aggregate reads its argument in,
		as `percentile_cont(0.5) WITHIN GROUP (ORDER BY x)` does. Null for every other function.
	**/
	public final WithinGroup:Null<Array<OrderByExpression>>;

	public function new(name:String, arguments:Array<ISqlExpression>, infix:Bool = false,
			?withinGroup:Array<OrderByExpression>) {
		this.Name = name;
		this.Arguments = arguments;
		this.Infix = infix;
		this.WithinGroup = withinGroup;
	}
}
