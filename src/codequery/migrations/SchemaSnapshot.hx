package codequery.migrations;

import codequery.migrations.DatabaseTableConstraint;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.SqlType;
#if macro
import codequery.sqlexpressions.ColumnsBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	A schema as a document, and back again; and the live, fluently-built schema a migration is
	scaffolded from — the C# `SchemaSnapshot`, which is a `DatabaseSchema` with a builder's surface.

	What a migration records beside its SQL, so the next one can be worked out as the difference
	from it rather than from the database — which is what lets a migration be scaffolded without a
	connection to anything.
**/
class SchemaSnapshot extends DatabaseSchema {
	/** The tables bound to entity classes, by the class's name — what `Entity(T)` looks up. */
	public final EntityTables:Map<String, DatabaseTableDefinition> = new Map();

	public function new(?name:String) {
		super([], name);
	}

	/**
		A table bound to an entity, empty until configured: `schema.DefineTable(Author, "authors")`.
		The C# tests' `DefineTable<T>(name)`.
	**/
	public macro function DefineTable(self:Expr, entity:Expr, ?name:Expr):Expr {
		final row = SchemaInspector.ClassOf(entity);
		final path = row.pack.concat([row.name]).join(".");
		final tableName = switch name {
			case null | {expr: EConst(CIdent("null"))}: macro $v{ColumnsBuilder.TableNameOf(row)};
			case given: given;
		}
		final type = TPath({pack: row.pack, name: row.name});
		return macro {
			final snapshot = $self;
			final table = snapshot.AddTable($tableName);
			snapshot.EntityTables.set($v{path}, table);
			(new codequery.migrations.EntityTableBuilder<$type>(table, snapshot) : codequery.migrations.EntityTableBuilder<$type>);
		};
	}

	/** The builder over an entity's table, which must already be there: `schema.Entity(Book)`. */
	public macro function Entity(self:Expr, entity:Expr):Expr {
		final row = SchemaInspector.ClassOf(entity);
		final path = row.pack.concat([row.name]).join(".");
		final type = TPath({pack: row.pack, name: row.name});
		return macro {
			final snapshot = $self;
			final table = snapshot.EntityTable($v{path}, $v{ColumnsBuilder.TableNameOf(row)}, $v{row.name});
			(new codequery.migrations.EntityTableBuilder<$type>(table, snapshot) : codequery.migrations.EntityTableBuilder<$type>);
		};
	}

	/** The table an entity is bound to, else the one of its name. */
	public function EntityTable(path:String, tableName:String, entityName:String):DatabaseTableDefinition {
		if (EntityTables.exists(path)) {
			return EntityTables.get(path);
		}
		final table = GetTable(tableName);
		if (table == null) {
			throw 'No table is configured for entity \'$entityName\'. Expose it as a DbTable<$entityName> entity on the schema (auto-inspected on build) before configuring it.';
		}
		return table;
	}

	/** Seed rows for an entity's table: `schema.Seed(Author, authors)`. */
	public macro function Seed(self:Expr, entity:Expr, records:Expr):Expr {
		final row = SchemaInspector.ClassOf(entity);
		final path = row.pack.concat([row.name]).join(".");
		return macro {
			final snapshot = $self;
			snapshot.SeedRows(snapshot.EntityTable($v{path}, $v{ColumnsBuilder.TableNameOf(row)}, $v{row.name}).Name, cast $records);
		};
	}

	/** A snapshot over tables already built. */
	public static function FromTables(tables:Array<DatabaseTableDefinition>, ?name:String):SchemaSnapshot {
		final snapshot = new SchemaSnapshot(name);
		snapshot.Tables = tables;
		return snapshot;
	}

	/** The same schema, with the builder's surface — the schema itself where it already has one. */
	public static function FromDatabaseSchema(schema:DatabaseSchema):SchemaSnapshot {
		final held = Std.downcast(schema, SchemaSnapshot);
		if (held != null) {
			return held;
		}
		final snapshot = new SchemaSnapshot(schema.Name);
		snapshot.Version = schema.Version;
		snapshot.Tables = schema.Tables;
		snapshot.Types = schema.Types;
		snapshot.Routines = schema.Routines;
		snapshot.Seeds = schema.Seeds;
		return snapshot;
	}

	/** The C# `FromSchema`: a schema is its own snapshot. */
	public static function FromSchema(schema:DatabaseSchema, ?name:String):SchemaSnapshot {
		final snapshot = FromDatabaseSchema(schema);
		if (name != null) {
			snapshot.Name = name;
		}
		return snapshot;
	}

	public function ToDatabaseSchema():DatabaseSchema {
		return this;
	}

	/** The table of that name, or null. */
	public function GetTable(name:String, ?schema:String):Null<DatabaseTableDefinition> {
		for (table in Tables) {
			if (table.Name.toLowerCase() == name.toLowerCase() && (schema == null || table.Schema == schema)) {
				return table;
			}
		}
		return null;
	}

	/** The table of that name, made if it was not there — the C# `Table(name)`. */
	public function AddTable(name:String, ?schema:String):DatabaseTableDefinition {
		final held = GetTable(name, schema);
		if (held != null) {
			return held;
		}
		final table = new DatabaseTableDefinition(name, [], schema);
		Tables.push(table);
		return table;
	}

	/** A view by its rendered SQL. */
	public function View(name:String, body:String, ?schema:String):SchemaSnapshot {
		return Routine(DatabaseRoutineKind.View, name, body, schema);
	}

	public function Routine(kind:DatabaseRoutineKind, name:String, body:String, ?schema:String):SchemaSnapshot {
		Routines.push(new DatabaseRoutineDefinition(kind, name, body, schema));
		return this;
	}

	/**
		Seed rows for a table already configured with a primary key. Each record is read by column
		name and written as a SQL literal, so the rows compare and diff as text.
	**/
	public function SeedRows(tableName:String, records:Array<Dynamic>):SchemaSnapshot {
		final table = GetTable(tableName);
		if (table == null) {
			throw 'No table is configured for \'$tableName\'; configure it before seeding.';
		}
		var key:Null<DatabasePrimaryKeyConstraint> = null;
		for (constraint in table.Constraints) {
			final pk = Std.downcast(constraint, DatabasePrimaryKeyConstraint);
			if (pk != null) {
				key = pk;
			}
		}
		if (key == null) {
			throw 'Table \'${table.Name}\' needs a primary key before it can be seeded.';
		}

		var seed:Null<SeedDataDefinition> = null;
		for (held in Seeds) {
			if (held.TableName.toLowerCase() == table.Name.toLowerCase() && held.Schema == table.Schema) {
				seed = held;
			}
		}
		if (seed == null) {
			seed = new SeedDataDefinition(table.Name, table.Schema);
			Seeds.push(seed);
		}
		seed.KeyColumns = key.Columns.copy();
		seed.Columns = [for (c in table.Columns) c.Name];

		for (record in records) {
			final row = new Map<String, String>();
			for (column in seed.Columns) {
				row.set(column, SqlLiteral.Format(Reflect.field(record, column)));
			}
			seed.Rows.push(row);
		}
		return this;
	}

	// ---- as a document ----------------------------------------------------------------------------

	public static function ToYaml(schema:DatabaseSchema):String {
		return SnapshotSerializer.Serialize(SchemaSnapshotDocument.FromModel(SchemaCanonicalizer.Canonical(schema)));
	}

	public static function FromYaml(yaml:String):DatabaseSchema {
		return SnapshotSerializer.Deserialize(yaml).ToModel();
	}

	/** A type as an earlier snapshot of this port wrote it — its own spelling, not any dialect's. */
	public static function TypeName(type:SqlType):String {
		return switch type {
			case SqlInt: "int";
			case SqlBigInt: "bigint";
			case SqlFloat: "float";
			case SqlDecimal(precision, scale): 'decimal($precision,$scale)';
			case SqlBool: "bool";
			case SqlText: "text";
			case SqlVarChar(length): 'varchar($length)';
			case SqlDate: "date";
			case SqlTimestamp: "timestamp";
			case SqlUnknown: "unknown";
			case SqlSmallInt: "smallint";
			case SqlChar(length): 'char($length)';
			case SqlGuid: "guid";
			case SqlJson: "json";
			case SqlBinary: "binary";
			case SqlTime: "time";
		}
	}

	public static function TypeOf(name:String):SqlType {
		if (StringTools.startsWith(name, "varchar(")) {
			return SqlVarChar(Std.parseInt(name.substring(8, name.length - 1)));
		}
		if (StringTools.startsWith(name, "char(")) {
			return SqlChar(Std.parseInt(name.substring(5, name.length - 1)));
		}
		if (StringTools.startsWith(name, "decimal(")) {
			final parts = name.substring(8, name.length - 1).split(",");
			return SqlDecimal(Std.parseInt(parts[0]), Std.parseInt(parts[1]));
		}
		return switch name {
			case "int": SqlInt;
			case "bigint": SqlBigInt;
			case "float": SqlFloat;
			case "bool": SqlBool;
			case "text": SqlText;
			case "date": SqlDate;
			case "timestamp": SqlTimestamp;
			case "smallint": SqlSmallInt;
			case "guid": SqlGuid;
			case "json": SqlJson;
			case "binary": SqlBinary;
			case "time": SqlTime;
			case _: SqlUnknown;
		}
	}
}
