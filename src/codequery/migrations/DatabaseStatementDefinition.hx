package codequery.migrations;

/** An object created by running a statement rather than by DDL the model knows. */
class DatabaseStatementDefinition {
	public var Name:String;
	public var Sql:String = "";
	public var UndoSql:Null<String>;
	public var Table:Null<String>;
	public var AfterRoutines:Bool = false;

	public function new(name:String) {
		this.Name = name;
	}
}
