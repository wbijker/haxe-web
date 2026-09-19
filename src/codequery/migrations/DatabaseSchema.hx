package codequery.migrations;

/**
	What the database should look like — the shape the entities describe, and the shape a snapshot
	records. A migration is the difference between two of these.
**/
class DatabaseSchema {
	public final Version:Int;
	public final Name:Null<String>;
	public final Tables:Array<DatabaseTableDefinition>;

	public function new(tables:Array<DatabaseTableDefinition>, ?name:String, version:Int = 1) {
		this.Tables = tables;
		this.Name = name;
		this.Version = version;
	}

	public function Table(name:String):Null<DatabaseTableDefinition> {
		for (table in Tables) {
			if (table.Name == name) {
				return table;
			}
		}
		return null;
	}

	/** Nothing yet — what the database looks like before any migration has run. */
	public static function Empty():DatabaseSchema {
		return new DatabaseSchema([]);
	}
}
