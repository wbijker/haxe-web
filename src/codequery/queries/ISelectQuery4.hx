package codequery.queries;

/**
	A SELECT over 4 rows, reached by joining. A lambda over it takes all 4, in the order they were joined.

	C#'s `ISelectQuery<T1, T2, T3, T4>`. Haxe has no overloading on the number of type parameters, so the
	arity is in the name. The clauses live in `SelectQueryExtensions`, brought in by `@:using`.
**/
@:forward(ToExpression, CountExpression, Count)
@:using(codequery.queries.SelectQueryExtensions)
abstract ISelectQuery4<T1, T2, T3, T4>(SelectQueryImpl) {
	/**
		The rows as the driver sent them: a query over several rows has no one row type to read
		them back as until a projection makes one. Runs the query, so it needs a connection.
	**/
	public inline function Fetch():Array<Map<String, Dynamic>> {
		return cast this.Fetch();
	}
}
