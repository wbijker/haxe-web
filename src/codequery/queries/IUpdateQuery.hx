package codequery.queries;

/**
	An UPDATE under construction.

	C#'s `IUpdateQuery<TTable>`. As with `ISelectQuery`, the clauses are macros and so live in
	`MutationQueryExtensions`, brought in by `@:using`.
**/
@:forward(ToExpression, Execute)
@:using(codequery.queries.MutationQueryExtensions)
abstract IUpdateQuery<TTable>(MutationQueryImpl) {}
