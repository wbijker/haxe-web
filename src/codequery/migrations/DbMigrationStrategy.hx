package codequery.migrations;

/**
	How a changed view is put into the database. The choice is part of the generated statement, so
	it travels into the snapshot and a change to it re-migrates the view. C#'s `DbMigrationStrategy`.
**/
enum DbMigrationStrategy {
	/** `CREATE OR REPLACE` — the default. What is there keeps its identity, so what depends on it survives. */
	CreateOrReplace;

	/** `DROP … IF EXISTS; CREATE …` — any change goes through, but the drop fails if something depends on it. */
	DropThenCreate;

	/** The same drop, cascading: whatever depends on the view goes with it, and is not put back. */
	DropCascadeThenCreate;

	/** The cascading drop with the dependants put back afterwards — PostgreSQL's catalogue makes it possible, and only its. */
	DropCascadeThenRestore;

	/** Create the view only if it is not there, and leave an existing one exactly as it is. */
	CreateIfAbsent;

	/** Build the new definition beside the old under a staging name, then rename it into place. */
	RenameSwap;
}
