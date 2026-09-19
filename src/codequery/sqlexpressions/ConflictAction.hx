package codequery.sqlexpressions;

/** What an insert does about a row that is already there. */
enum ConflictAction {
	DoNothing;
	DoUpdate;
}
