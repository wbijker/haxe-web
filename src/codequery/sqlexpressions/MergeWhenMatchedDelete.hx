package codequery.sqlexpressions;

/** `WHEN MATCHED THEN DELETE`. */
class MergeWhenMatchedDelete extends MergeAction {
	public function new(?condition:ISqlExpression) {
		super(condition);
	}
}
