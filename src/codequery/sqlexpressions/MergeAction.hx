package codequery.sqlexpressions;

/** One `WHEN [NOT] MATCHED [AND …] THEN …` clause of a `MergeExpression`. */
class MergeAction {
	/** An extra `AND <condition>` refining when the clause fires, or null. */
	public final Condition:Null<ISqlExpression>;

	function new(condition:Null<ISqlExpression>) {
		this.Condition = condition;
	}
}
