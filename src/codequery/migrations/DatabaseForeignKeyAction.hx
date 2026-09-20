package codequery.migrations;

/** What a foreign key does when what it points at goes — the C# `DatabaseForeignKeyAction`. */
enum DatabaseForeignKeyAction {
	NoAction;
	Cascade;
	SetNull;
	SetDefault;
	Restrict;
}
