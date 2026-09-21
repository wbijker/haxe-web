package codequery.sqldrivers;

import codequery.execution.IDatabaseExecutor;
import codequery.sqlexpressions.ISqlStatement;
import codequery.sqlexpressions.SqlConstValue;

/**
	Base for a driver built from a translator and a connection.

	Every rendering call is forwarded to the translator, so a driver only has to say how the SQL is
	executed — which is the one thing that differs between one runtime and another. A driver made
	without a connection renders and refuses to run, which is a useful thing to be able to make.
**/
class SqlDriver implements ISqlDriver {
	public var Translator(default, null):ISqlTranslator;
	public var ConnectionString(default, null):Null<String>;

	public function new(translator:ISqlTranslator, ?connectionString:String) {
		this.Translator = translator;
		this.ConnectionString = connectionString;
	}

	public var Parameters(default, null):Array<SqlConstValue> = [];

	public function ToSql(statement:ISqlStatement):String {
		final sql = Translator.ToSql(statement);
		Parameters = Translator.Parameters;
		return sql;
	}

	public function Placeholder(ordinal:Int):String {
		return Translator.Placeholder(ordinal);
	}

	public function ToDdl(change:codequery.migrations.SchemaChange):String {
		return Translator.ToDdl(change);
	}

	public function ToDdlSql(change:codequery.sqlexpressions.SchemaChangeExpression, pretty:Bool = false):String {
		return Translator.ToDdlSql(change, pretty);
	}

	public function MigrationHistoryDdl(table:String):String {
		return Translator.MigrationHistoryDdl(table);
	}

	/** Nothing to run against unless a runtime says otherwise. */
	public function Executor():Null<IDatabaseExecutor> {
		return null;
	}
}
