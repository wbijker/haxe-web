package codequery.sqlexpressions;

/** Whether a comparison must hold for one row of a subquery or for every row. */
enum Quantifier {
	Any;
	All;
}
