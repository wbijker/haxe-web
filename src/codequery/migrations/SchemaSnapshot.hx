package codequery.migrations;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	A point-in-time snapshot of a schema, for comparison and migration generation.

	Two things at once, as the C# class is: the tables a schema has been built into, with each
	entity bound to its table so a fluent configuration can find it; and, as a document, what a
	migration records beside its SQL, so the next one can be worked out as the difference from it
	rather than from the database.
**/
class SchemaSnapshot {
	public var Version:Int = 1;
	public var Id:String;
	public var Name:Null<String>;
	public var CreatedAt:Date = Date.now();
	public var Description:Null<String>;
	public var Tables:Array<DatabaseTableDefinition> = [];

	/** Objects created by running a statement, compared by their SQL. */
	public var Statements:Array<DatabaseStatementDefinition> = [];

	/**
		Each entity's table, by the entity's class path. C# keys this by `Type`; a class path is
		what Haxe has for one at runtime, and it is what every macro here writes down.
	**/
	public final EntityTables = new Map<String, DatabaseTableDefinition>();

	public function new(?name:String) {
		this.Name = name;
		this.Id = StringTools.hex(Std.random(0x7fffffff), 8).toLowerCase();
	}

	public static function FromTables(tables:Array<DatabaseTableDefinition>, ?name:String):SchemaSnapshot {
		final snapshot = new SchemaSnapshot(name);
		snapshot.Tables = tables.copy();
		return snapshot;
	}

	public function ToDatabaseSchema():DatabaseSchema {
		final schema = new DatabaseSchema();
		schema.Version = Version;
		schema.Name = Name;
		schema.CreatedAt = CreatedAt;
		schema.Description = Description;
		schema.Tables = Tables;
		return schema;
	}

	public static function FromDatabaseSchema(schema:DatabaseSchema):SchemaSnapshot {
		final snapshot = new SchemaSnapshot(schema.Name);
		snapshot.Version = schema.Version;
		snapshot.CreatedAt = schema.CreatedAt == null ? Date.now() : schema.CreatedAt;
		snapshot.Description = schema.Description;
		snapshot.Tables = schema.Tables;
		return snapshot;
	}

	/** A table by its name. */
	public function TableNamed(tableName:String, ?schema:String):Null<DatabaseTableDefinition> {
		return ToDatabaseSchema().GetTable(tableName, schema);
	}

	/** The table an entity is bound to, by the entity's class path, or null. */
	public function TableOf(entity:String):Null<DatabaseTableDefinition> {
		return EntityTables.get(entity);
	}

	/**
		A table by name — `GetTable("Users")` — or the table an entity is bound to — `GetTable(Book)`.
		C# spells the second `GetTable<Book>()`; here the argument says which is meant.
	**/
	public macro function GetTable(self:Expr, which:Expr, ?schema:Expr):Expr {
		return switch which.expr {
			case EConst(CString(_)): macro $self.TableNamed($which, $schema);
			case _: macro $self.TableOf($v{SchemaMembers.ClassPathOf(which)});
		}
	}

	/** Adds a new, empty table and answers with it. */
	public function Table(name:String, ?schema:String):DatabaseTableDefinition {
		final table = new DatabaseTableDefinition(name, schema);
		Tables.push(table);
		return table;
	}

	/** Binds an entity to a table already in the snapshot: `snapshot.Bind(Trip, definition)`. */
	public macro function Bind(self:Expr, entity:Expr, definition:Expr):Expr {
		return macro $self.EntityTables.set($v{SchemaMembers.ClassPathOf(entity)}, $definition);
	}

	/**
		A typed builder over the table an entity is bound to — `schema.Entity(Book)` — for
		configuring what inspection could not say. Throws where the entity has no table.
	**/
	public macro function Entity(self:Expr, entity:Expr):Expr {
		final row = SchemaMembers.TypeOf(entity);
		final path = SchemaMembers.ClassPathOf(entity);
		final name = SchemaMembers.ClassNameOf(entity);
		final type = haxe.macro.TypeTools.toComplexType(row);
		return macro($self.EntityNamed($v{path}, $v{name}) : codequery.migrations.EntityTableBuilder<$type>);
	}

	/** What `Entity` expands to; the builder is typed at the call. */
	public function EntityNamed(path:String, name:String):Dynamic {
		final table = TableOf(path);
		if (table == null) {
			throw 'No table is configured for entity \'$name\'. Expose it as a DbTable<$name> on the schema (auto-inspected on build) before configuring it.';
		}
		return new EntityTableBuilder<Dynamic>(table, this);
	}

	/**
		Registers an object created by running `sql`, under the stable identity `name`. Registering
		the same name twice replaces it.
	**/
	public function Statement(name:String, sql:String, ?undoSql:String, ?table:String, afterRoutines:Bool = false):SchemaSnapshot {
		var statement = null;
		for (candidate in Statements) {
			if (candidate.Name.toLowerCase() == name.toLowerCase()) {
				statement = candidate;
			}
		}
		if (statement == null) {
			statement = new DatabaseStatementDefinition(name);
			Statements.push(statement);
		}
		statement.Sql = sql;
		statement.UndoSql = undoSql;
		statement.Table = table;
		statement.AfterRoutines = afterRoutines;
		return this;
	}

	// ---- as a document ---------------------------------------------------------------------------

	/** A schema as YAML — what a migration records beside its SQL. */
	public static function ToYaml(schema:DatabaseSchema):String {
		return Yaml.Emit(DatabaseSchemaSerializer.ToDocument(schema));
	}

	public static function FromYaml(yaml:String):DatabaseSchema {
		final document = Yaml.Parse(yaml);
		return document == null ? DatabaseSchema.Empty() : DatabaseSchemaSerializer.FromDocument(document);
	}
}
