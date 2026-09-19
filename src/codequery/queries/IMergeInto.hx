package codequery.queries;

/** A MERGE awaiting its source and match condition — C#'s `MergeBuilder<TTarget>`. */
@:using(codequery.queries.MergeExtensions)
abstract IMergeInto<TTarget>(MergeBuilderImpl) {}
