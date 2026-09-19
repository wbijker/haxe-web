package codequery.queries;

/**
	A DELETE under construction.

	C#'s `IDeleteQuery<T>`. As with `ISelectQuery`, the clauses are macros and so live in
	`MutationQueryExtensions`, brought in by `@:using`.
**/
@:forward(ToExpression, Execute)
@:using(codequery.queries.MutationQueryExtensions)
abstract IDeleteQuery<T>(MutationQueryImpl) {}
