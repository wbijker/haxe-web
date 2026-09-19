package codequery.queries;

/**
	A MERGE accumulating its WHEN clauses — C#'s `MergeBuilder<TTarget, TSource>`. A lambda over it
	names the target's row first and the source's second.
**/
@:forward(Build)
@:using(codequery.queries.MergeExtensions)
abstract IMergeBuilder<TTarget, TSource>(MergeBuilderImpl) {}
