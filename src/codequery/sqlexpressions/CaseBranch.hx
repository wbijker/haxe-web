package codequery.sqlexpressions;

/** One `WHEN <condition> THEN <result>` of a CASE. */
class CaseBranch {
	public final When:ISqlExpression;
	public final Then:ISqlExpression;

	public function new(when:ISqlExpression, then:ISqlExpression) {
		this.When = when;
		this.Then = then;
	}
}
