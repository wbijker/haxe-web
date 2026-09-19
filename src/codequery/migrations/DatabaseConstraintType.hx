package codequery.migrations;

enum DatabaseConstraintType {
	PrimaryKey;
	ForeignKey;
	Unique;
	Check;
	Default;
}
