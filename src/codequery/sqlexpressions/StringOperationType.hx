package codequery.sqlexpressions;

/** Which part of a string a search term has to match. */
enum StringOperationType {
	/** `LIKE '%term%'`. */
	Contains;

	/** `LIKE 'term%'`. */
	StartsWith;

	/** `LIKE '%term'`. */
	EndsWith;
}
