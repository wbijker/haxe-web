package codequery.migrations;

import codequery.migrations.DatabaseColumnType;
import codequery.migrations.DatabaseIndexDefinition;
import codequery.migrations.DatabaseTableConstraint;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.SqlType;
#if macro
import codequery.sqlexpressions.ColumnsBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
#end

/** One column as the inspector read it off a field. */
typedef InspectedColumn = {
	name:String,
	type:SqlType,
	nullable:Bool,
	key:Bool,
	autoIncrement:Bool,
	identity:IdentityKind,
	?defaultValue:String
}

/** One foreign key as its metadata declared it. */
typedef InspectedForeignKey = {
	column:String,
	table:String,
	referencedColumn:String,
	onDelete:String,
	onUpdate:String,
	index:Bool
}

/** One `@index` on one column: what gathers it, and how it sorts. */
typedef InspectedIndex = {
	key:String,
	?name:String,
	ordinal:Int,
	column:String,
	order:Int,
	unique:Bool,
	clustered:Bool,
	descending:Bool
}

/**
	Reads a table off an entity class, while compiling — the C# `SchemaInspector.FromType<T>()`.

	The columns come from the public fields, as `ColumnsBuilder` reads them for a query; the key
	from `id` or `@primaryKey`; the foreign keys from `@foreignKey(Entity, …)`; the indexes from
	`@index(…)`; and a default from a field's initializer, where it is a constant.

	```haxe
	@:foreignKey(Unit, onDelete = Cascade) public var unitId:Int = 0;
	@:index("IX_guest_country_joined", order = 0) public var country:String = "";
	@:index(group = "unit_check_in", order = 1) public var code:String = "";
	@:primaryKey(identity = Always) public var id:Int = 0;
	```

	Written with the colon: an argument that is not a constant — a class, `order = 0` — is only
	allowed on compile-time metadata, which is the only place this is read.
**/
class SchemaInspector {
	public static macro function FromType(entity:Expr):Expr {
		return TableExpr(ClassOf(entity), entity.pos);
	}

	#if macro
	/**
		The class an expression names — `Job` written as a value. With `near`, a bare name is looked
		for beside that class first: metadata on an entity names its neighbours as the entity's own
		module sees them, wherever the schema is later read from.
	**/
	public static function ClassOf(e:Expr, ?near:ClassType):ClassType {
		if (near != null) {
			switch e.expr {
				case EConst(CIdent(name)):
					for (path in [near.module + "." + name, near.pack.concat([name]).join(".")]) {
						try {
							switch Context.getType(path).follow() {
								case TInst(t, _): return t.get();
								case _:
							}
						} catch (_:Dynamic) {}
					}
				case _:
			}
		}
		return switch Context.typeof(e) {
			case TType(_.get() => {type: TAnonymous(_.get() => {status: AClassStatics(c)})}, _): c.get();
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', e.pos);
		}
	}

	/** The expression that builds the table `row` declares. */
	public static function TableExpr(row:ClassType, pos:Position):Expr {
		final columns:Array<Expr> = [];
		final keys:Array<InspectedForeignKey> = [];
		final indexes:Array<InspectedIndex> = [];
		var keyGenerated = true;
		ColumnsOf(row, [], [], columns, keys, indexes, pos);

		for (field in row.fields.get()) {
			if (IsKeyField(field) && Flag(Metas(field, "primaryKey"), "autoIncrement", true) == false) {
				keyGenerated = false;
			}
		}

		final columnList = {expr: EArrayDecl(columns), pos: pos};
		final keyList = macro $v{keys};
		final indexList = macro $v{indexes};
		return macro codequery.migrations.SchemaInspector.Assemble($v{ColumnsBuilder.TableNameOf(row)}, $columnList, $keyList,
			$indexList, $v{keyGenerated});
	}

	/** The same walk `ColumnsBuilder` does, so a schema and a query agree about a table. */
	static function ColumnsOf(row:ClassType, member:Array<String>, visited:Array<String>, into:Array<Expr>,
			keys:Array<InspectedForeignKey>, indexes:Array<InspectedIndex>, pos:Position):Void {
		for (field in row.fields.get()) {
			if (!field.isPublic || !field.kind.match(FVar(AccNormal | AccNo, _))) {
				continue;
			}

			final nested = switch field.type.follow() {
				case TInst(t, _):
					final held = t.get();
					final path = held.pack.concat([held.name]).join(".");
					(path == "String" || path == "Date") ? null : held;
				case _: null;
			}

			if (nested != null) {
				final path = nested.pack.concat([nested.name]).join(".");
				if (visited.indexOf(path) >= 0) {
					Context.error('${row.name}.${field.name} contains itself', pos);
				}
				ColumnsOf(nested, member.concat([ColumnsBuilder.ColumnNameOf(field)]), visited.concat([path]), into, keys, indexes, pos);
				continue;
			}

			final name = member.concat([ColumnsBuilder.ColumnNameOf(field)]).join(ColumnsBuilder.Separator);
			final type = ColumnsBuilder.SqlTypeOfField(field);
			// A key is the one column the database fills in, and a nested member is never one.
			final key = member.length == 0 && IsKeyField(field);
			final autoIncrement = key && Flag(Metas(field, "primaryKey"), "autoIncrement", true);
			final identity = key ? IdentityOf(field) : "ByDefault";
			final defaultValue = key || autoIncrement ? null : DeclaredDefault(field);

			into.push(macro {
				name: $v{name},
				type: $type,
				nullable: $v{IsNullable(field)},
				key: $v{key},
				autoIncrement: $v{autoIncrement},
				identity: $p{["codequery", "sqlexpressions", "ColumnDefinition", "IdentityKind", identity]},
				defaultValue: $v{defaultValue}
			});

			if (member.length == 0) {
				final foreignKey = ForeignKeyOf(row, field, name, pos);
				if (foreignKey != null) {
					keys.push(foreignKey);
				}
				for (index in IndexesOf(field, name, indexes.length)) {
					indexes.push(index);
				}
			}
		}
	}

	static function IsKeyField(field:ClassField):Bool {
		return field.name == "id" || field.meta.has("primaryKey") || field.meta.has(":primaryKey");
	}

	/** The metadata by either spelling: `@name` as the entities already write it, `@:name` where it takes arguments. */
	static function Metas(field:ClassField, name:String):Array<MetadataEntry> {
		return field.meta.extract(name).concat(field.meta.extract(":" + name));
	}

	/** `@primaryKey(identity = Always)`, else the ordinary form. */
	static function IdentityOf(field:ClassField):String {
		final metas = Metas(field, "primaryKey");
		final named:Null<Expr> = metas.length == 0 ? null : Named(metas[0].params, "identity");
		return switch named {
			case {expr: EConst(CIdent(v))} if (v == "Always" || v == "Serial" || v == "ByDefault"): v;
			case _: "ByDefault";
		}
	}

	/**
		A default read from the field's initializer, where it is a constant. A value that would be
		different the next time the entity is made — a date now, a fresh id — is not a default a
		schema can hold; and the type's own zero is what a column has anyway.
	**/
	static function DeclaredDefault(field:ClassField):Null<String> {
		final init = field.expr();
		if (init == null) {
			return null;
		}
		return switch init.expr {
			case TConst(TInt(v)) if (v != 0): Std.string(v);
			case TConst(TFloat(v)) if (Std.parseFloat(v) != 0): v;
			case TConst(TBool(v)) if (v): "1";
			case TConst(TString(v)) if (v != ""): "'" + StringTools.replace(v, "'", "''") + "'";
			case TCast(inner, _): DeclaredDefaultOf(inner);
			case _: null;
		}
	}

	static function DeclaredDefaultOf(e:TypedExpr):Null<String> {
		return switch e.expr {
			case TConst(TInt(v)) if (v != 0): Std.string(v);
			case TConst(TString(v)) if (v != ""): "'" + StringTools.replace(v, "'", "''") + "'";
			case TCast(inner, _): DeclaredDefaultOf(inner);
			case _: null;
		}
	}

	/**
		Whether a column takes a null: `Null<T>` says so, and so does `@columnNullable(false)` saying
		the opposite — C# writes that on a string, the one type whose Haxe spelling does not already
		say it.
	**/
	public static function IsNullable(field:ClassField):Bool {
		final stated = switch field.meta.extract("columnNullable") {
			case [{params: [{expr: EConst(CIdent(v))}]}]: v == "true";
			case _: null;
		}
		if (stated != null) {
			return stated;
		}
		return IsNullableType(field.type);
	}

	public static function IsNullableType(type:Type):Bool {
		return switch type {
			case TType(t, _) if (t.get().name == "Null"): true;
			case TAbstract(t, _) if (t.get().name == "Null"): true;
			// A string holds a null whether or not it is spelled that way.
			case TInst(t, _) if (t.get().name == "String"): true;
			case _: false;
		}
	}

	/** `@foreignKey(Entity)`, with `column = "…"`, `onDelete = Cascade`, `onUpdate = …`, `index = false` beside it. */
	static function ForeignKeyOf(row:ClassType, field:ClassField, column:String, pos:Position):Null<InspectedForeignKey> {
		final metas = Metas(field, "foreignKey");
		if (metas.length == 0) {
			return null;
		}
		final params = metas[0].params;
		if (params.length == 0) {
			Context.error("@foreignKey names the entity it points at: @foreignKey(Author)", metas[0].pos);
		}
		final referenced = ClassOf(params[0], row);
		final referencedColumn = switch Named(params, "column") {
			case {expr: EConst(CString(v, _))}: v;
			case _: PrimaryKeyColumnOf(referenced);
		}
		return {
			column: column,
			table: ColumnsBuilder.TableNameOf(referenced),
			referencedColumn: referencedColumn,
			onDelete: ActionOf(Named(params, "onDelete")),
			onUpdate: ActionOf(Named(params, "onUpdate")),
			index: Flag(metas, "index", true)
		};
	}

	static function ActionOf(e:Null<Expr>):String {
		return switch e {
			case {expr: EConst(CIdent(v))} if (v == "Cascade" || v == "SetNull" || v == "SetDefault" || v == "Restrict"): v;
			case _: "NoAction";
		}
	}

	/** The column `entity` is keyed by: `id`, or the field carrying `@primaryKey`; `id` when it has neither. */
	static function PrimaryKeyColumnOf(entity:ClassType):String {
		for (field in entity.fields.get()) {
			if (field.isPublic && field.kind.match(FVar(AccNormal | AccNo, _)) && IsKeyField(field)) {
				return ColumnsBuilder.ColumnNameOf(field);
			}
		}
		return "id";
	}

	/**
		Every `@index` on the field: `@index`, `@index("name")`, and `unique`, `clustered`,
		`descending`, `order`, `group` beside it. A name gathers columns as it always did; a group
		gathers without saying anything about the name; a column with neither is an index of its own.
	**/
	static function IndexesOf(field:ClassField, column:String, ordinal:Int):Array<InspectedIndex> {
		final found:Array<InspectedIndex> = [];
		for (meta in Metas(field, "index")) {
			final name = switch meta.params {
				case [{expr: EConst(CString(v, _))}]: v;
				case params if (params.length > 0):
					switch params[0].expr {
						case EConst(CString(v, _)): v;
						case _: null;
					}
				case _: null;
			}
			final group = switch Named(meta.params, "group") {
				case {expr: EConst(CString(v, _))}: v;
				case _: null;
			}
			final order = switch Named(meta.params, "order") {
				case {expr: EConst(CInt(v, _))}: Std.parseInt(v);
				case _: 0;
			}
			found.push({
				key: name != null ? name : (group != null ? "group:" + group : "column:" + column + ":" + ordinal),
				name: name,
				ordinal: ordinal++,
				column: column,
				order: order,
				unique: Flag([meta], "unique", false),
				clustered: Flag([meta], "clustered", false),
				descending: Flag([meta], "descending", false)
			});
		}
		return found;
	}

	/** The `name = value` parameter of a metadata, or null. */
	static function Named(params:Array<Expr>, name:String):Null<Expr> {
		if (params == null) {
			return null;
		}
		for (param in params) {
			switch param.expr {
				case EBinop(OpAssign, {expr: EConst(CIdent(n))}, value) if (n == name): return value;
				case _:
			}
		}
		return null;
	}

	static function Flag(metas:Array<MetadataEntry>, name:String, otherwise:Bool):Bool {
		for (meta in metas) {
			switch Named(meta.params, name) {
				case {expr: EConst(CIdent("true"))}: return true;
				case {expr: EConst(CIdent("false"))}: return false;
				case _:
			}
		}
		return otherwise;
	}
	#end

	/**
		The table, from what the macro read: the primary key `PK_{table}`, a foreign key
		`FK_{table}_{column}` for each reference, the indexes gathered by name or group, and an index
		on each foreign key column unless it said otherwise or the key already leads one.
	**/
	static function Action(name:String):DatabaseForeignKeyAction {
		return switch name {
			case "Cascade": Cascade;
			case "SetNull": SetNull;
			case "SetDefault": SetDefault;
			case "Restrict": Restrict;
			case _: NoAction;
		}
	}

	public static function Assemble(table:String, columns:Array<InspectedColumn>, foreignKeys:Array<InspectedForeignKey>,
			indexes:Array<InspectedIndex>, keyGenerated:Bool):DatabaseTableDefinition {
		final definition = new DatabaseTableDefinition(table, []);
		final keyColumns:Array<String> = [];

		for (read in columns) {
			final column = new DatabaseColumnDefinition(read.name, read.type, read.nullable, read.key);
			column.OrdinalIndex = definition.Columns.length;
			column.IsAutoIncrement = read.autoIncrement;
			column.Identity = read.identity;
			column.DefaultValue = read.defaultValue;
			definition.Columns.push(column);
			if (read.key) {
				keyColumns.push(read.name);
			}
		}

		if (keyColumns.length > 0) {
			final key = new DatabasePrimaryKeyConstraint('PK_$table', keyColumns);
			key.Generation = keyGenerated ? ServerGenerated : ClientGenerated;
			definition.Constraints.push(key);
		}

		for (fk in foreignKeys) {
			definition.Constraints.push(new DatabaseForeignKeyConstraint('FK_${table}_${fk.column}', [fk.column], fk.table,
				[fk.referencedColumn], Action(fk.onDelete), Action(fk.onUpdate)));
		}

		// Indexes, gathered by what keys them, in the order each first appeared.
		final groups:Array<Array<InspectedIndex>> = [];
		for (entry in indexes) {
			var group:Null<Array<InspectedIndex>> = null;
			for (held in groups) {
				if (held[0].key.toLowerCase() == entry.key.toLowerCase()) {
					group = held;
				}
			}
			if (group == null) {
				groups.push([entry]);
			} else {
				group.push(entry);
			}
		}
		for (group in groups) {
			group.sort((a, b) -> a.order != b.order ? a.order - b.order : a.ordinal - b.ordinal);
			final index = new DatabaseIndexDefinition(group[0].name != null ? group[0].name : 'IX_${table}_${[for (e in group) e.column].join("_")}',
				[for (e in group) new DatabaseIndexColumn(e.column, e.descending ? Descending : Ascending)]);
			for (e in group) {
				if (e.unique) {
					index.IsUnique = true;
				}
				if (e.clustered) {
					index.IsClustered = true;
				}
			}
			definition.Indexes.push(index);
		}

		// A foreign key column is indexed unless it opted out, or the key or an index already leads with it.
		for (fk in foreignKeys) {
			if (!fk.index) {
				continue;
			}
			var covered = keyColumns.length > 0 && keyColumns[0] == fk.column;
			for (index in definition.Indexes) {
				if (index.Columns.length > 0 && index.Columns[0].ColumnName == fk.column) {
					covered = true;
				}
			}
			if (!covered) {
				definition.Indexes.push(new DatabaseIndexDefinition('IX_${table}_${fk.column}', [new DatabaseIndexColumn(fk.column)]));
			}
		}

		return definition;
	}
}
