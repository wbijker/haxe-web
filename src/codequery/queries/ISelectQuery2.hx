package codequery.queries;

/**
	A SELECT over 2 rows, reached by joining. A lambda over it takes all 2, in the order they were joined.

	C#'s `ISelectQuery<T1, T2>`. Haxe has no overloading on the number of type parameters, so the
	arity is in the name. The clauses live in `SelectQueryExtensions`, brought in by `@:using`.
**/
@:forward(ToExpression, CountExpression, Count, Fetch)
@:using(codequery.queries.SelectQueryExtensions)
abstract ISelectQuery2<T1, T2>(SelectQueryImpl) {}
