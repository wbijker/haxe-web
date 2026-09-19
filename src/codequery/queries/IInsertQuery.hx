package codequery.queries;

/**
	An INSERT under construction, once it has something to say beyond the rows.

	C#'s `Upsert(…).OnConflict(…).Update(…)`. The clauses are macros, so they live in
	`InsertQueryExtensions`, brought in by `@:using`.
**/
@:forward(ToExpression, Execute)
@:using(codequery.queries.InsertQueryExtensions)
abstract IInsertQuery<TTable>(InsertQueryImpl) {}
