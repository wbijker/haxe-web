package codequery.sqlexpressions;

/** One `UNION`/`INTERSECT`/`EXCEPT` and the statement on its right. */
class UnionSqlExpression {
	public final Type:SetOperationType;
	public final Query:SelectExpression;

	public function new(type:SetOperationType, query:SelectExpression) {
		this.Type = type;
		this.Query = query;
	}
}
