package codequery.migrations;

enum DatabaseForeignKeyAction {
	NoAction;
	Cascade;
	SetNull;
	SetDefault;
	Restrict;
}
