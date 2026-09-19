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

	public function new(name:String, arguments:Array<ISqlExpression>, infix:Bool = false) {
		this.Name = name;
		this.Arguments = arguments;
		this.Infix = infix;
	}
}
