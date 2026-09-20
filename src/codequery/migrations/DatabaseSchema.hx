package codequery.migrations;

import codequery.sqlexpressions.SchemaChangeExpression;

/**
	What the database should look like — the shape the entities describe, and the shape a snapshot
	records. A migration is the difference between two of these.
**/
class DatabaseSchema {
	public var Version:Int;
	public var Name:Null<String>;
	public var CreatedAt:Null<Date>;
	public var Description:Null<String>;
	public var Provider:Null<String>;
	public var Tables:Array<DatabaseTableDefinition>;
	public var Types:Array<DatabaseObjectTypeDefinition> = [];
	public var Routines:Array<DatabaseRoutineDefinition> = [];
	public var Seeds:Array<SeedDataDefinition> = [];

	/** Objects created by running a statement, compared by their SQL. */
	public var Statements:Array<DatabaseStatementDefinition> = [];

	/** The views the schema declares — C#'s view routines. */
	public final Views:Array<DatabaseViewDefinition>;

	/**
		`new DatabaseSchema()`, `new DatabaseSchema("name")` — the C# constructors — or, with the
		tables first, the schema a class declares as `SchemaBuilder.Of` builds it.
	**/
	public function new(?tables:Array<DatabaseTableDefinition>, ?name:String, version:Int = 1,
			?views:Array<DatabaseViewDefinition>) {
		this.Tables = tables == null ? [] : tables;
		this.Name = name;
		this.Version = version;
		this.Views = views == null ? [] : views;
		if (name != null) {
			this.CreatedAt = Date.now();
		}
	}

	public static function FromTables(tables:Array<DatabaseTableDefinition>, ?name:String):DatabaseSchema {
		final schema = new DatabaseSchema(tables.copy(), name);
		schema.CreatedAt = Date.now();
		return schema;
	}

	public function GetView(name:String):Null<DatabaseViewDefinition> {
		for (view in Views) {
			if (view.Name == name) {
				return view;
			}
		}
		return null;
	}

	/** The table of exactly that name, or null. */
	public function Table(name:String):Null<DatabaseTableDefinition> {
		for (table in Tables) {
			if (table.Name == name) {
				return table;
			}
		}
		return null;
	}

	/**
		Adds a table — the C# `AddTable(table)` — or, given a name, the table of that name, made if
		it was not there. Either way the answer is the table, to configure on.
	**/
	public function AddTable(which:haxe.extern.EitherType<String, DatabaseTableDefinition>, ?schema:String):DatabaseTableDefinition {
		if (Std.isOfType(which, String)) {
			final held = TableNamed(which, schema);
			if (held != null) {
				return held;
			}
			final table = new DatabaseTableDefinition(which, [], schema);
			Tables.push(table);
			return table;
		}
		final table:DatabaseTableDefinition = which;
		Tables.push(table);
		return table;
	}

	/**
		The table of that name — `GetTable("Users", "dbo")` — or the table an entity is bound to,
		`GetTable(Book)`. C# spells the second `GetTable<Book>()`; here the argument says which is
		meant, and a class is as good a value as a string.
	**/
	public function GetTable(which:haxe.extern.EitherType<String, Class<Dynamic>>, ?schema:String):Null<DatabaseTableDefinition> {
		if (Std.isOfType(which, String)) {
			return TableNamed(which, schema);
		}
		final path = Type.getClassName(which);
		return path == null ? null : TableOf(path);
	}

	/** The table of that name, regardless of case, as a database finds it. */
	public function TableNamed(tableName:String, ?schema:String):Null<DatabaseTableDefinition> {
		for (table in Tables) {
			if (table.Name.toLowerCase() == tableName.toLowerCase() && (schema == null || Same(table.Schema, schema))) {
				return table;
			}
		}
		return null;
	}

	/** The table an entity is bound to, by the entity's class path; a plain schema binds none. */
	public function TableOf(entity:String):Null<DatabaseTableDefinition> {
		return null;
	}

	static function Same(a:Null<String>, b:Null<String>):Bool {
		return (a == null && b == null) || (a != null && b != null && a.toLowerCase() == b.toLowerCase());
	}

	static function Key(table:DatabaseTableDefinition):String {
		return (table.Schema == null || table.Schema == "" ? table.Name : '${table.Schema}.${table.Name}').toLowerCase();
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
				changes.push(new DropTableExpression(table.Name, table.Schema, true));
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

	/** Nothing yet — what the database looks like before any migration has run. */
	public static function Empty():DatabaseSchema {
		return new DatabaseSchema([]);
	}
}
