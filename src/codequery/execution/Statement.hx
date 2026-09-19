package codequery.execution;

import codequery.sqlexpressions.SqlConstValue;

/** One statement, and the values sent beside it. */
typedef Statement = {
	final Sql:String;
	final Parameters:Array<SqlConstValue>;
}
