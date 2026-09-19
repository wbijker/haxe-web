package codequery.sqlexpressions;

/**
	One `WITH name AS (…)` in front of a statement.

	A query given a name, so the statement after it can select from that name — and, where it is
	recursive, so the query can select from itself.
**/
class CommonTableExpression {
	public final Name:String;
	public final Query:SelectExpression;
	public final Recursive:Bool;

	public function new(name:String, query:SelectExpression, recursive:Bool = false) {
		this.Name = name;
		this.Query = query;
		this.Recursive = recursive;
	}
}
