package codequery.sqlexpressions;

/** A CTE, selected from by the name it was given. */
class CteSqlSource implements ISqlSource {
	public final Cte:CommonTableExpression;
	public var Alias(default, null):String;

	public function new(cte:CommonTableExpression, alias:String) {
		this.Cte = cte;
		this.Alias = alias;
	}
}
