package codequery.execution;

/** A place in the code: the file, the line, and the member there — `CodeQuery.Execution.SourceLocation`. */
typedef SourceLocation = {
	final File:String;
	final Line:Int;
	final Member:Null<String>;
}
