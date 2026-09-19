package codequery.sqlexpressions;

/** A subquery in a FROM or a JOIN, under the alias the statement gave it. */
class QuerySqlSource implements ISqlSource {
	public final Query:SelectExpression;
	public var Alias(default, null):String;

	/**
		Whether this is the source `Select` wraps its projection in, so that the clauses after it
		read the projected columns. Such a wrapper is not a statement anyone wrote, and a column the
		projected statement reads from further out counts statements without it.
	**/
	public final Projected:Bool;

	public function new(query:SelectExpression, alias:String, projected:Bool = false) {
		this.Query = query;
		this.Alias = alias;
		this.Projected = projected;
	}
}
