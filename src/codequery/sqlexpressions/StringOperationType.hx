package codequery.sqlexpressions;

/** What a string is tested for: `LIKE '%x%'`, `LIKE 'x%'`, `LIKE '%x'`. */
enum StringOperationType {
	Contains;
	StartsWith;
	EndsWith;
}
