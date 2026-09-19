package codequery.queries;

/**
	An `UPDATE … FROM <source>` under construction.

	C#'s `IUpdateQuery<TTable, TSource>`. The clauses live in `MutationQueryExtensions`, brought in by `@:using`;
	a lambda over one of these names the target's row first and the source's second.
**/
@:forward(ToExpression, Execute)
@:using(codequery.queries.MutationQueryExtensions)
abstract IUpdateQuery2<TTable, TSource>(MutationQueryImpl) {}
