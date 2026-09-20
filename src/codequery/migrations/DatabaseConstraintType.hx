package codequery.migrations;

/** Which kind a constraint is — the C# `DatabaseConstraintType`. */
enum DatabaseConstraintType {
	PrimaryKey;
	ForeignKey;
	Unique;
	Check;
	Default;
}
