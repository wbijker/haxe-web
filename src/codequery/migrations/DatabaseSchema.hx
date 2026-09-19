package codequery.migrations;

import codequery.sqlexpressions.SchemaChangeExpression;

/**
	What the database should look like — the shape the entities describe, and the shape a snapshot
	records. A migration is the difference between two of these.
**/
class DatabaseSchema {
	public var Version:Int = 1;
	public var Name:Null<String>;
	public var CreatedAt:Null<Date>;
	public var Description:Null<String>;
	public var Provider:Null<String>;
	public var Tables:Array<DatabaseTableDefinition> = [];

	public function new(?name:String) {
		if (name != null) {
			this.Name = name;
			this.CreatedAt = Date.now();
		}
	}

	public static function FromTables(tables:Array<DatabaseTableDefinition>, ?name:String):DatabaseSchema {
		final schema = new DatabaseSchema();
		schema.Name = name;
		schema.CreatedAt = Date.now();
		schema.Tables = tables.copy();
		return schema;
	}

	/** Nothing yet — what the database looks like before any migration has run. */
	public static function Empty():DatabaseSchema {
		return new DatabaseSchema();
	}

	public function AddTable(table:DatabaseTableDefinition):DatabaseSchema {
		Tables.push(table);
		return this;
	}

	public function GetTable(tableName:String, ?schema:String):Null<DatabaseTableDefinition> {
		for (table in Tables) {
			if (table.TableName.toLowerCase() == tableName.toLowerCase() && Same(table.Schema, schema)) {
				return table;
			}
		}
		return null;
	}

	static function Same(a:Null<String>, b:Null<String>):Bool {
		return (a == null && b == null) || (a != null && b != null && a.toLowerCase() == b.toLowerCase());
	}

	static function Key(table:DatabaseTableDefinition):String {
		return (table.Schema == null || table.Schema == "" ? table.TableName : '${table.Schema}.${table.TableName}').toLowerCase();
	}

	/** The changes that turn `from` into this schema — or, from nothing, the changes that make it. */
	public function Diff(from:Null<DatabaseSchema>):Array<SchemaChangeExpression> {
		var changes:Array<SchemaChangeExpression> = [];

		if (from == null) {
			for (table in Tables) {
				changes = changes.concat(table.Diff(null));
			}
			return changes;
		}

		final fromTables = new Map<String, DatabaseTableDefinition>();
		for (table in from.Tables) {
			fromTables.set(Key(table), table);
		}
		final toTables = new Map<String, DatabaseTableDefinition>();
		for (table in Tables) {
			toTables.set(Key(table), table);
		}

		for (table in from.Tables) {
			if (!toTables.exists(Key(table))) {
				changes.push(new DropTableExpression(table.TableName, table.Schema, true));
			}
		}

		for (table in Tables) {
			if (!fromTables.exists(Key(table))) {
				changes = changes.concat(table.Diff(null));
			}
		}

		for (table in Tables) {
			final was = fromTables.get(Key(table));
			if (was != null) {
				changes = changes.concat(table.Diff(was));
			}
		}

		return changes;
	}

	/** The changes that turn `from` into `to`; the static form of `Diff`. */
	public static function DiffFrom(from:Null<DatabaseSchema>, to:DatabaseSchema):Array<SchemaChangeExpression> {
		return to.Diff(from);
	}
}
