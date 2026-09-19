package codequery.migrations;

/**
	A set of seed rows for a table. Rows are identified by `KeyColumns` and compared whole-record to
	find inserts, updates and deletes. Each row maps a column name to its SQL literal.
**/
class SeedDataDefinition {
	public var TableName:String;
	public var Schema:Null<String> = null;
	public var KeyColumns:Array<String> = [];
	public var Columns:Array<String> = [];
	public var Rows:Array<Map<String, String>> = [];

	public function new(tableName:String = "", ?schema:String) {
		this.TableName = tableName;
		this.Schema = schema;
	}
}
