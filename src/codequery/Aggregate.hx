package codequery;

/**
	An aggregate under construction, inside a `SelectAggregation`.

	Nothing here runs: the projection it appears in is read while compiling and becomes an
	`AggregateSqlExpression`. It exists so that the projection type-checks, and so that an editor
	can see what an aggregate offers.
**/
extern class Aggregate<T> {
	/** Reads the aggregate over a window rather than over the whole group. */
	public function over(window:INamedWindow):T;
}
