package codequery.sqlexpressions;

/** A subquery in a FROM or a JOIN, under the alias the statement gave it. */
class QuerySqlSource implements ISqlSource {
	public final Query:SelectExpression;
	public var Alias(default, null):String;

	public function new(query:SelectExpression, alias:String) {
		this.Query = query;
		this.Alias = alias;
	}
}
