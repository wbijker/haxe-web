package codequery.sqlexpressions;

/** What a statement selects, when it selects something other than its rows. */
class ProjectionSqlExpression implements ISqlExpression {
	public final Members:Array<ProjectionMember>;

	public function new(members:Array<ProjectionMember>) {
		this.Members = members;
	}
}
