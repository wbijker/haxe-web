package codequery.sqldrivers;

import codequery.execution.IDatabaseExecutor;

/**
	A dialect plus a way to run it.

	The rendering half is inherited from the translator, so a caller can keep asking the driver for
	SQL; what a driver adds is everything about *where* that SQL goes.
**/
interface ISqlDriver extends ISqlTranslator {
	/** What this driver connects with, or null where it was made only to render. */
	var ConnectionString(default, null):Null<String>;

	/** The translator this driver's SQL is rendered by. */
	var Translator(default, null):ISqlTranslator;

	/** An executor bound to this driver's connection. Null where it has none. */
	function Executor():Null<IDatabaseExecutor>;
}
