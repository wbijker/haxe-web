package codequery.sqlexpressions;

/** The window functions — the ones that are not aggregates. */
enum WindowFunction {
	RowNumber;
	Rank;
	DenseRank;
	Lead;
	Lag;
	FirstValue;
	LastValue;
}
