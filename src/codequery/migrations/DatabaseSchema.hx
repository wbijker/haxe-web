package codequery.migrations;

/**
	What the database should look like — the shape the entities describe, and the shape a snapshot
	records. A migration is the difference between two of these.
**/
class DatabaseSchema {
	public var Version:Int;
	public var Name:Null<String>;
	public var Tables:Array<DatabaseTableDefinition>;
	public var Types:Array<DatabaseObjectTypeDefinition> = [];
	public var Routines:Array<DatabaseRoutineDefinition> = [];
	public var Seeds:Array<SeedDataDefinition> = [];

	/** The views the schema declares — C#'s view routines. */
	public final Views:Array<DatabaseViewDefinition>;

	public function new(tables:Array<DatabaseTableDefinition>, ?name:String, version:Int = 1,
			?views:Array<DatabaseViewDefinition>) {
		this.Tables = tables;
		this.Name = name;
		this.Version = version;
		this.Views = views == null ? [] : views;
	}

	public function GetView(name:String):Null<DatabaseViewDefinition> {
		for (view in Views) {
			if (view.Name == name) {
				return view;
			}
		}
		return null;
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
