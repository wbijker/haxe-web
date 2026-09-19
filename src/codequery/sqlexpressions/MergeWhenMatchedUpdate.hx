package codequery.sqlexpressions;

/** `WHEN MATCHED THEN UPDATE SET …`. */
class MergeWhenMatchedUpdate extends MergeAction {
	public final Assignments:Array<MergeAssignment>;

	public function new(assignments:Array<MergeAssignment>, ?condition:ISqlExpression) {
		super(condition);
		this.Assignments = assignments;
	}
}
