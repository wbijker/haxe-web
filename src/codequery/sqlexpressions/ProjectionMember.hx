package codequery.sqlexpressions;

/** One member of a projection: what it selects, and the name it comes back under. */
class ProjectionMember {
	/** Empty where the projection is one expression that names nothing — `a -> a.name`. */
	public final Name:String;

	public final Expression:ISqlExpression;

	public function new(name:String, expression:ISqlExpression) {
		this.Name = name;
		this.Expression = expression;
	}
}
