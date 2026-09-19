package codequery.runtimes.php;

import codequery.execution.IDatabaseExecutor;
import codequery.sqldrivers.SqlDriver;

/**
	A driver for the PHP runtime: the PDO dialect, and a PDO connection to send it down.

	Made without a connection string it still renders — which is what a driver made only to
	generate SQL is for — and answers with no executor, so asking it to run says so plainly.
**/
class PhpDriver extends SqlDriver {
	#if php
	var executor:Null<PdoExecutor>;
	#end

	public function new(?connectionString:String) {
		super(new PdoTranslator(), connectionString);
	}

	override public function Executor():Null<IDatabaseExecutor> {
		#if php
		if (ConnectionString == null) {
			return null;
		}
		if (executor == null) {
			executor = PdoExecutor.Connect(ConnectionString);
		}
		return executor;
		#else
		return null;
		#end
	}
}
