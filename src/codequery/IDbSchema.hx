package codequery;

/**
	A schema declared as a plain class: every `DbTable` member constructs itself, and
	`DatabaseInitializer.Build` reads the members off the class while compiling.
**/
interface IDbSchema {}
