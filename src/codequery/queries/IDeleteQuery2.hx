package codequery.queries;

/**
	A `DELETE … USING <source>` under construction.

	C#'s `IDeleteQuery<TTable, TSource>`. The clauses live in `MutationQueryExtensions`, brought in by `@:using`;
	a lambda over one of these names the target's row first and the source's second.
**/
@:forward(ToExpression, Execute)
@:using(codequery.queries.MutationQueryExtensions)
abstract IDeleteQuery2<TTable, TSource>(MutationQueryImpl) {}
