package codequery.migrations;

import codequery.migrations.DatabaseColumnType;
import codequery.migrations.DatabaseTableConstraint;
import codequery.migrations.DatabaseIndexDefinition;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.SchemaChangeExpression;

/** A YAML node with its members in the order they were given, which is what makes a file stable. */
private enum Node {
	Scalar(text:String);
	Block(lines:String);
	Sequence(items:Array<Node>);
	Mapping(members:Array<{key:String, value:Node}>);
}

/**
	Reads and writes the `snapshot.yaml` kept in each migration folder.

	Null values and empty collections are left out, so the document stays compact; a multi-line
	string — a view's body — is written as a literal block (`|`) so it reads as it was written; and
	a column's place is said by where it is listed, not by a number that would shift under every
	column below an inserted one.
**/
class SnapshotSerializer {
	public static function Serialize(document:SchemaSnapshotDocument):String {
		final schema = document.Schema;
		final root:Array<{key:String, value:Node}> = [{key: "version", value: Scalar(Std.string(document.Version))}];
		if (document.BaseHash != null) {
			root.push({key: "baseHash", value: Scalar(document.BaseHash)});
		}
		Add(root, "tables", [for (t in schema.Tables) Table(t)]);
		Add(root, "types", [for (t in schema.Types) ObjectType(t)]);
		Add(root, "routines", [for (r in schema.Routines) Routine(r)]);
		Add(root, "seeds", [for (s in schema.Seeds) Seed(s)]);

		final out = new StringBuf();
		Write(out, Mapping(root), 0);
		return out.toString();
	}

	static function Add(into:Array<{key:String, value:Node}>, key:String, items:Array<Node>):Void {
		if (items.length > 0) {
			into.push({key: key, value: Sequence(items)});
		}
	}

	static function Text(into:Array<{key:String, value:Node}>, key:String, value:Null<String>):Void {
		if (value != null) {
			into.push({key: key, value: value.indexOf("\n") >= 0 ? Block(value) : Scalar(value)});
		}
	}

	static function Table(t:DatabaseTableDefinition):Node {
		final members:Array<{key:String, value:Node}> = [];
		Text(members, "name", t.Name);
		Text(members, "schema", t.Schema);
		Add(members, "columns", [for (c in t.Columns) Column(c)]);
		Add(members, "constraints", [for (c in t.Constraints) Constraint(c)]);
		Add(members, "indexes", [for (i in t.Indexes) Index(i)]);
		return Mapping(members);
	}

	static function Column(c:DatabaseColumnDefinition):Node {
		final members:Array<{key:String, value:Node}> = [];
		Text(members, "name", c.Name);
		Text(members, "type", Std.string(c.Type));
		Text(members, "nullable", c.Nullable ? "true" : "false");
		if (c.IsAutoIncrement) {
			Text(members, "autoIncrement", "true");
			if (c.Identity != ByDefault) {
				Text(members, "identity", Std.string(c.Identity));
			}
		}
		Text(members, "default", c.DefaultValue);
		Text(members, "maxLength", c.MaxLength == null ? null : Std.string(c.MaxLength));
		Text(members, "precision", c.Precision == null ? null : Std.string(c.Precision));
		Text(members, "scale", c.Scale == null ? null : Std.string(c.Scale));
		Text(members, "collation", c.Collation);
		Text(members, "comment", c.Comment);
		return Mapping(members);
	}

	static function Constraint(c:DatabaseTableConstraint):Node {
		final members:Array<{key:String, value:Node}> = [];
		Text(members, "kind", Std.string(c.ConstraintType()));
		Text(members, "name", c.Name);

		final pk = Std.downcast(c, DatabasePrimaryKeyConstraint);
		final fk = Std.downcast(c, DatabaseForeignKeyConstraint);
		final unique = Std.downcast(c, DatabaseUniqueConstraint);
		final check = Std.downcast(c, DatabaseCheckConstraint);
		if (pk != null) {
			Add(members, "columns", [for (n in pk.Columns) Scalar(n)]);
			if (pk.Generation != ServerGenerated) {
				Text(members, "generation", Std.string(pk.Generation));
			}
		} else if (fk != null) {
			Add(members, "columns", [for (n in fk.Columns) Scalar(n)]);
			Text(members, "referencedTable", fk.ReferencedTable);
			Text(members, "referencedSchema", fk.ReferencedSchema);
			Add(members, "referencedColumns", [for (n in fk.ReferencedColumns) Scalar(n)]);
			Text(members, "onDelete", Std.string(fk.OnDelete));
			Text(members, "onUpdate", Std.string(fk.OnUpdate));
		} else if (unique != null) {
			Add(members, "columns", [for (n in unique.Columns) Scalar(n)]);
		} else if (check != null) {
			Text(members, "expression", check.Expression);
		}
		return Mapping(members);
	}

	static function Index(i:DatabaseIndexDefinition):Node {
		final members:Array<{key:String, value:Node}> = [];
		Text(members, "name", i.Name);
		Add(members, "columns", [
			for (c in i.Columns) {
				final column:Array<{key:String, value:Node}> = [{key: "columnName", value: Scalar(c.ColumnName)}];
				if (c.SortOrder == Descending) {
					column.push({key: "sortOrder", value: Scalar("Descending")});
				}
				Mapping(column);
			}
		]);
		if (i.IsUnique) {
			Text(members, "isUnique", "true");
		}
		if (i.IsClustered) {
			Text(members, "isClustered", "true");
		}
		Text(members, "filterExpression", i.FilterExpression);
		Add(members, "includeColumns", [for (n in i.IncludeColumns) Scalar(n)]);
		Text(members, "method", i.Method);
		return Mapping(members);
	}

	static function ObjectType(t:DatabaseObjectTypeDefinition):Node {
		final members:Array<{key:String, value:Node}> = [];
		Text(members, "name", t.Name);
		Text(members, "schema", t.Schema);
		Add(members, "fields", [for (f in t.Fields) Column(f)]);
		if (t.EnumValues != null) {
			Add(members, "enumValues", [for (v in t.EnumValues) Scalar(v)]);
		}
		if (t.IsDomain) {
			Text(members, "isDomain", "true");
		}
		return Mapping(members);
	}

	static function Routine(r:DatabaseRoutineDefinition):Node {
		final members:Array<{key:String, value:Node}> = [];
		Text(members, "kind", Std.string(r.Kind));
		Text(members, "name", r.Name);
		Text(members, "schema", r.Schema);
		Text(members, "body", r.Body);
		if (r.Materialized) {
			Text(members, "materialized", "true");
		}
		if (r.Inline) {
			Text(members, "inline", "true");
		}
		Text(members, "returnType", r.ReturnType);
		Text(members, "tableName", r.TableName);
		return Mapping(members);
	}

	static function Seed(s:SeedDataDefinition):Node {
		final members:Array<{key:String, value:Node}> = [];
		Text(members, "tableName", s.TableName);
		Text(members, "schema", s.Schema);
		Add(members, "keyColumns", [for (n in s.KeyColumns) Scalar(n)]);
		Add(members, "columns", [for (n in s.Columns) Scalar(n)]);
		Add(members, "rows", [
			for (row in s.Rows)
				Mapping([for (c in s.Columns) if (row.exists(c)) {key: c, value: Scalar(row.get(c))}])
		]);
		return Mapping(members);
	}

	// ---- writing ----------------------------------------------------------------------------------

	static function Write(out:StringBuf, node:Node, depth:Int):Void {
		final pad = StringTools.rpad("", " ", depth * 2);
		switch node {
			case Scalar(text):
				out.add('$pad${Quote(text)}\n');
			case Block(lines):
				out.add('$pad|\n');
				for (line in lines.split("\n")) {
					out.add('$pad  $line\n');
				}
			case Sequence(items):
				for (item in items) {
					switch item {
						case Mapping(members):
							out.add('$pad- ');
							WriteMembers(out, members, depth + 1, true);
						case Scalar(text):
							out.add('$pad- ${Quote(text)}\n');
						case _:
							out.add('$pad-\n');
							Write(out, item, depth + 1);
					}
				}
			case Mapping(members):
				WriteMembers(out, members, depth, false);
		}
	}

	/** A mapping's members, the first on the dash's own line when it is a list item. */
	static function WriteMembers(out:StringBuf, members:Array<{key:String, value:Node}>, depth:Int, afterDash:Bool):Void {
		final pad = StringTools.rpad("", " ", depth * 2);
		var first = afterDash;
		for (member in members) {
			final lead = first ? "" : pad;
			first = false;
			switch member.value {
				case Scalar(text):
					out.add('$lead${member.key}: ${Quote(text)}\n');
				case Block(lines):
					out.add('$lead${member.key}: |\n');
					for (line in lines.split("\n")) {
						out.add('$pad  $line\n');
					}
				case Sequence(_):
					out.add('$lead${member.key}:\n');
					Write(out, member.value, depth);
				case Mapping(inner):
					out.add('$lead${member.key}:\n');
					WriteMembers(out, inner, depth + 1, false);
			}
		}
	}

	/** Quoted where it would otherwise read as something else — a number, a boolean, nothing. */
	static function Quote(text:String):String {
		if (text == "") {
			return '""';
		}
		final plain = ~/^[A-Za-z_][A-Za-z0-9_.\-]*$/;
		if (plain.match(text) && text != "null" && text != "true" && text != "false") {
			return text;
		}
		if (~/^-?[0-9]+$/.match(text) || text == "true" || text == "false") {
			return text;
		}
		return '"' + StringTools.replace(StringTools.replace(text, "\\", "\\\\"), '"', '\\"') + '"';
	}

	// ---- reading ----------------------------------------------------------------------------------

	public static function Deserialize(yaml:String):SchemaSnapshotDocument {
		final document = new SchemaSnapshotDocument();
		final parsed:Dynamic = Yaml.Parse(yaml);
		if (parsed == null) {
			return document;
		}
		if (Field(parsed, "version") != null) {
			document.Version = Std.parseInt(Std.string(Field(parsed, "version")));
		}
		final baseHash = Field(parsed, "baseHash");
		document.BaseHash = baseHash == null ? null : Std.string(baseHash);

		final schema = document.Schema;
		schema.Version = document.Version;
		schema.Tables = [for (t in List(parsed, "tables")) ReadTable(t)];
		schema.Types = [for (t in List(parsed, "types")) ReadType(t)];
		schema.Routines = [for (r in List(parsed, "routines")) ReadRoutine(r)];
		schema.Seeds = [for (s in List(parsed, "seeds")) ReadSeed(s)];
		return document;
	}

	static function ReadTable(t:Dynamic):DatabaseTableDefinition {
		final table = new DatabaseTableDefinition(Str(t, "name"), [], Str(t, "schema"));
		var ordinal = 0;
		for (c in List(t, "columns")) {
			final column = ReadColumn(c);
			column.OrdinalIndex = ordinal++;
			table.Columns.push(column);
		}
		table.Constraints = [for (c in List(t, "constraints")) ReadConstraint(c)];
		table.Indexes = [for (i in List(t, "indexes")) ReadIndex(i)];
		return table;
	}

	static function ReadColumn(c:Dynamic):DatabaseColumnDefinition {
		final column = DatabaseColumnDefinition.Of(Str(c, "name"), DatabaseColumnTypes.Parse(Str(c, "type")),
			Field(c, "nullable") == null ? true : Bool(c, "nullable"));
		column.IsAutoIncrement = Bool(c, "autoIncrement");
		final identity = Str(c, "identity");
		column.Identity = identity == "Always" ? Always : (identity == "Serial" ? Serial : ByDefault);
		column.DefaultValue = Str(c, "default");
		column.MaxLength = Int(c, "maxLength");
		column.Precision = Int(c, "precision");
		column.Scale = Int(c, "scale");
		column.Collation = Str(c, "collation");
		column.Comment = Str(c, "comment");
		return column;
	}

	static function ReadConstraint(c:Dynamic):DatabaseTableConstraint {
		final columns = [for (n in List(c, "columns")) Std.string(n)];
		return switch Str(c, "kind") {
			case "PrimaryKey":
				final pk = new DatabasePrimaryKeyConstraint(Str(c, "name"), columns);
				if (Str(c, "generation") == "ClientGenerated") {
					pk.Generation = ClientGenerated;
				}
				pk;
			case "ForeignKey":
				new DatabaseForeignKeyConstraint(Str(c, "name"), columns, Str(c, "referencedTable"),
					[for (n in List(c, "referencedColumns")) Std.string(n)], ReadAction(Str(c, "onDelete")),
					ReadAction(Str(c, "onUpdate")), Str(c, "referencedSchema"));
			case "Unique":
				new DatabaseUniqueConstraint(Str(c, "name"), columns);
			case "Check":
				new DatabaseCheckConstraint(Str(c, "name"), Str(c, "expression"));
			case kind:
				throw 'Unknown constraint kind $kind';
		}
	}

	static function ReadAction(name:Null<String>):DatabaseForeignKeyAction {
		return switch name {
			case "Cascade": Cascade;
			case "SetNull": SetNull;
			case "SetDefault": SetDefault;
			case "Restrict": Restrict;
			case _: NoAction;
		}
	}

	static function ReadIndex(i:Dynamic):DatabaseIndexDefinition {
		final index = new DatabaseIndexDefinition(Str(i, "name"), [
			for (c in List(i, "columns"))
				new DatabaseIndexColumn(Str(c, "columnName"), Str(c, "sortOrder") == "Descending" ? Descending : Ascending)
		]);
		index.IsUnique = Bool(i, "isUnique");
		index.IsClustered = Bool(i, "isClustered");
		index.FilterExpression = Str(i, "filterExpression");
		index.IncludeColumns = [for (n in List(i, "includeColumns")) Std.string(n)];
		index.Method = Str(i, "method");
		return index;
	}

	static function ReadType(t:Dynamic):DatabaseObjectTypeDefinition {
		final type = new DatabaseObjectTypeDefinition(Str(t, "name"), [for (f in List(t, "fields")) ReadColumn(f)]);
		type.Schema = Str(t, "schema");
		if (Field(t, "enumValues") != null) {
			type.EnumValues = [for (v in List(t, "enumValues")) Std.string(v)];
		}
		type.IsDomain = Bool(t, "isDomain");
		return type;
	}

	static function ReadRoutine(r:Dynamic):DatabaseRoutineDefinition {
		final kind = switch Str(r, "kind") {
			case "Function": Function;
			case "Procedure": Procedure;
			case "Trigger": Trigger;
			case _: View;
		}
		final routine = new DatabaseRoutineDefinition(kind, Str(r, "name"), Str(r, "body"), Str(r, "schema"));
		routine.Materialized = Bool(r, "materialized");
		routine.Inline = Bool(r, "inline");
		routine.ReturnType = Str(r, "returnType");
		routine.TableName = Str(r, "tableName");
		return routine;
	}

	static function ReadSeed(s:Dynamic):SeedDataDefinition {
		final seed = new SeedDataDefinition(Str(s, "tableName"), Str(s, "schema"));
		seed.KeyColumns = [for (n in List(s, "keyColumns")) Std.string(n)];
		seed.Columns = [for (n in List(s, "columns")) Std.string(n)];
		seed.Rows = [
			for (row in List(s, "rows")) {
				final cells = new Map<String, String>();
				for (name in Reflect.fields(row)) {
					cells.set(name, Std.string(Reflect.field(row, name)));
				}
				cells;
			}
		];
		return seed;
	}

	static function Field(o:Dynamic, name:String):Dynamic {
		return o == null ? null : Reflect.field(o, name);
	}

	static function List(o:Dynamic, name:String):Array<Dynamic> {
		final held = Field(o, name);
		return held == null || !Std.isOfType(held, Array) ? [] : held;
	}

	static function Str(o:Dynamic, name:String):Null<String> {
		final held = Field(o, name);
		return held == null ? null : Std.string(held);
	}

	static function Int(o:Dynamic, name:String):Null<Int> {
		final held = Field(o, name);
		return held == null ? null : Std.parseInt(Std.string(held));
	}

	static function Bool(o:Dynamic, name:String):Bool {
		final held = Field(o, name);
		return held == true || Std.string(held) == "true";
	}
}
