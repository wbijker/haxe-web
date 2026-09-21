package codequery.queries;

/**
	A SELECT over 7 rows, reached by joining. A lambda over it takes all 7, in the order they were joined.

	C#'s `ISelectQuery<T1, T2, T3, T4, T5, T6, T7>`. Haxe has no overloading on the number of type parameters, so the
	arity is in the name. The clauses live in `SelectQueryExtensions`, brought in by `@:using`.
**/
@:forward(ToExpression, CountExpression, Count, Fetch)
@:using(codequery.queries.SelectQueryExtensions)
abstract ISelectQuery7<T1, T2, T3, T4, T5, T6, T7>(SelectQueryImpl) {}
