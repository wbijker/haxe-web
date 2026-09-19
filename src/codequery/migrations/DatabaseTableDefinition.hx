package codequery.migrations;

/** A table, as the schema describes it. */
class DatabaseTableDefinition {
	public final Name:String;
	public final Schema:Null<String>;
	public final Columns:Array<DatabaseColumnDefinition>;

	/** `CREATE TEMPORARY TABLE` — gone when the session is. */
	public final Temporary:Bool;

	/** `CREATE UNLOGGED TABLE` — not written to the log, so faster and not crash-safe. */
	public final Unlogged:Bool;

	public function new(name:String, columns:Array<DatabaseColumnDefinition>, ?schema:String,
			temporary:Bool = false, unlogged:Bool = false) {
		this.Name = name;
		this.Columns = columns;
		this.Schema = schema;
		this.Temporary = temporary;
		this.Unlogged = unlogged;
	}

	public function Column(name:String):Null<DatabaseColumnDefinition> {
		for (column in Columns) {
			if (column.Name == name) {
				return column;
			}
		}
		return null;
	}
}
