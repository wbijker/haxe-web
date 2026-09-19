package codequery.migrations;

/** A table, as the schema describes it. */
class DatabaseTableDefinition {
	public final Name:String;
	public final Schema:Null<String>;
	public final Columns:Array<DatabaseColumnDefinition>;

	public function new(name:String, columns:Array<DatabaseColumnDefinition>, ?schema:String) {
		this.Name = name;
		this.Columns = columns;
		this.Schema = schema;
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
