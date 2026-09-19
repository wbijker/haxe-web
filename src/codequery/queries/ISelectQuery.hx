package codequery.queries;

/**
	A SELECT under construction — the type a caller holds.

	C#'s `ISelectQuery<T1>`. Haxe has no overloading on the number of type parameters, so the
	arity is in the name. The clauses live in `SelectQueryExtensions`, brought in by `@:using`.
**/
@:forward(ToExpression, CountExpression, Count)
@:using(codequery.queries.SelectQueryExtensions)
abstract ISelectQuery<T1>(SelectQueryImpl) {}
