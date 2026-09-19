package codequery.sqlexpressions;

/** How two statements' rows are put together. */
enum SetOperationType {
	Union;
	UnionAll;
	Intersect;
	IntersectAll;
	Except;
	ExceptAll;
}
