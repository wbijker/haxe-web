package codequery;

import codequery.execution.SqlOutcome;
import codequery.execution.SqlQuery;

/**
	Told of every statement a configuration's driver is sent, before it goes and after it comes
	back — `CodeQuery.ISqlLogger`. Registered with `DatabaseConfiguration.WithLogger`.
**/
interface ISqlLogger {
	function BeforeSend(query:SqlQuery):Void;

	function AfterSend(query:SqlQuery, outcome:SqlOutcome):Void;
}
