package codequery.sqlexpressions;

/** `CASE WHEN … THEN … ELSE … END`. */
class CaseSqlExpression implements ISqlExpression {
	public final Branches:Array<CaseBranch>;
	public final Otherwise:Null<ISqlExpression>;

	public function new(branches:Array<CaseBranch>, ?otherwise:ISqlExpression) {
		this.Branches = branches;
		this.Otherwise = otherwise;
	}
}
