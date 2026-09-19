package codequery.sqlexpressions;

/** Plain grouping, or one of the two that also group the totals. */
enum GroupingMode {
	None;
	Rollup;
	Cube;

	/** `GROUPING SETS (…)` — the groupings named one by one. */
	GroupingSets;
}
