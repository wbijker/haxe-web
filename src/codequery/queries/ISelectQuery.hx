package codequery.queries;

/**
	A SELECT under construction — the type a caller holds.

	C#'s `ISelectQuery<T1>`. Haxe has no overloading on the number of type parameters, so the
	arity is in the name. The clauses live in `SelectQueryExtensions`, brought in by `@:using`.
**/
@:forward(ToExpression, CountExpression, Count)
@:using(codequery.queries.SelectQueryExtensions)
abstract ISelectQuery<T1>(SelectQueryImpl) {
	/**
		The rows, read back as the row type: entities for a query over a table, the structures a
		projection built, the values a lone expression selects. Runs the query, so it needs a
		connection to run against.
	**/
	public inline function Fetch():Array<T1> {
		return cast this.Fetch();
	}
}
