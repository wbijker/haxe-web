package codequery.sqlexpressions;

/** Whether an insert may write a column the database generates. */
enum IdentityOverride {
	None;
	SystemValue;
	UserValue;
}
