package codequery;

/**
	A window a query has defined, as a row of it.

	`Window` answers with a query of one more row than it was asked of, and that extra row is this:
	it is how a projection afterwards names the window its aggregates read over.
**/
interface INamedWindow {}
