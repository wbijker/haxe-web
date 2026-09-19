package codequery.sqlexpressions;

/** One member of a projection: the name it comes back under, and what it selects. */
class ProjectionMember {
	public final Name:String;
	public final Expression:ISqlExpression;

	public function new(name:String, expression:ISqlExpression) {
		this.Name = name;
		this.Expression = expression;
	}
}
