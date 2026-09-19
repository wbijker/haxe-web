package codequery.sqlexpressions;

/**
	`CASE WHEN … THEN … ELSE … END` — or, with an operand, `CASE x WHEN value THEN … END`, where
	each arm's `When` is a value the operand is compared to rather than a condition.
**/
class CaseSqlExpression implements ISqlExpression {
	public final Branches:Array<CaseBranch>;
	public final Otherwise:Null<ISqlExpression>;

	/** What a simple CASE compares against each arm; null for a searched CASE, which tests each arm. */
	public final Operand:Null<ISqlExpression>;

	public function new(branches:Array<CaseBranch>, ?otherwise:ISqlExpression, ?operand:ISqlExpression) {
		this.Branches = branches;
		this.Otherwise = otherwise;
		this.Operand = operand;
	}
}
