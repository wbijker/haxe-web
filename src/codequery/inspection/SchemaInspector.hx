package codequery.inspection;

import codequery.migrations.DatabasePrimaryKeyConstraint;
import codequery.migrations.DatabaseForeignKeyConstraint;
import codequery.migrations.DatabaseUniqueConstraint;
import codequery.migrations.DatabaseForeignKeyAction;
import codequery.migrations.DatabaseIndexColumn;

import codequery.migrations.DatabaseTableConstraint;
import codequery.migrations.DatabaseIndexDefinition;

#if macro
import codequery.migrations.SchemaMembers;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
#end

/**
	Reads a table definition off an entity class — the C# `SchemaInspector`, done while compiling.

	C# reflects over the type's properties and their attributes at runtime. Haxe has the same
	information while compiling — the fields and their metadata — so `FromType(Book)` becomes the
	code that builds the definition, and nothing is looked up at runtime. The rules are the C#
	ones: `id` or `{Type}Id` is the key, an integer key auto-increments, a string is unbounded text
	until `@columnMaxLength` says otherwise, a `Null<T>` or a string takes null, and a property
	initialised to a value declares that value as the column's default.
**/
class SchemaInspector {
	/** The definition of the table an entity maps to: `SchemaInspector.FromType(Book)`. */
	public static macro function FromType(entity:Expr):Expr {
		return Inspect(SchemaMembers.ClassTypeOf(entity), entity.pos);
	}

	/** Several at once: `SchemaInspector.FromTypes(Book, Author)`. */
	public static macro function FromTypes(entities:Array<Expr>):Expr {
		return {expr: EArrayDecl([for (entity in entities) Inspect(SchemaMembers.ClassTypeOf(entity), entity.pos)]), pos: Context.currentPos()};
	}

	#if macro
	/** The code that builds the definition of the table `row` maps to. */
	public static function Inspect(row:ClassType, pos:Position):Expr {
		final tableName = TableNameOf(row);
		final schema = SchemaOf(row);

		final columns = try ColumnSpecs(row, pos) catch (refused:Refused) {
			return macro(throw $v{refused.message} : codequery.migrations.DatabaseTableDefinition);
		}

		final statements:Array<Expr> = [];
		statements.push(macro final __table = new codequery.migrations.DatabaseTableDefinition($v{tableName}, $v{schema}));

		for (index => column in columns) {
			statements.push(macro __table.Columns.push(${ColumnExpr(column, index)}));
		}

		final keyColumns = [for (column in columns) if (column.primaryKey) column.name];
		if (keyColumns.length > 0) {
			final generation = macro $p{["codequery", "ValueGeneration", columns.filter(c -> c.primaryKey)[0].generation]};
			statements.push(macro __table.Constraints.push(new codequery.migrations.DatabasePrimaryKeyConstraint(
				$v{'PK_$tableName'}, $v{keyColumns}, $generation)));
		}

		final indexed:Array<Array<String>> = [];
		for (column in columns) {
			final fk = column.foreignKey;
			if (fk == null) {
				continue;
			}
			final onDelete = macro $p{["codequery", "migrations", "DatabaseForeignKeyAction", fk.onDelete]};
			final onUpdate = macro $p{["codequery", "migrations", "DatabaseForeignKeyAction", fk.onUpdate]};
			statements.push(macro __table.Constraints.push(new codequery.migrations.DatabaseForeignKeyConstraint(
				$v{'FK_${tableName}_${column.name}'}, [$v{column.name}], $v{fk.table}, [$v{fk.column}], $onDelete, $onUpdate)));
		}

		for (column in columns) {
			if (column.unique) {
				statements.push(macro __table.Constraints.push(new codequery.migrations.DatabaseUniqueConstraint(
					$v{'UQ_${tableName}_${column.name}'}, [$v{column.name}])));
			}
		}

		// A foreign key column is indexed unless the key or an index already leads with it.
		for (column in columns) {
			final fk = column.foreignKey;
			if (fk == null || !fk.index || keyColumns[0] == column.name) {
				continue;
			}
			statements.push(macro __table.Indexes.push(new codequery.migrations.DatabaseIndexDefinition(
				$v{'IX_${tableName}_${column.name}'}, [new codequery.migrations.DatabaseIndexColumn($v{column.name})])));
		}

		statements.push(macro __table);
		return {expr: EBlock(statements), pos: pos};
	}

	static function ColumnExpr(column:ColumnSpec, ordinal:Int):Expr {
		final type = macro $p{["codequery", "migrations", "DatabaseColumnType", column.type]};
		final statements:Array<Expr> = [];
		statements.push(macro final __column = new codequery.migrations.DatabaseColumnDefinition($v{column.name}, $type, $v{column.nullable}));
		statements.push(macro __column.OrdinalIndex = $v{ordinal});
		if (column.autoIncrement) {
			statements.push(macro __column.IsAutoIncrement = true);
		}
		if (column.identity != "ByDefault") {
			statements.push(macro __column.Identity = $p{["codequery", "IdentityKind", column.identity]});
		}
		if (column.serverGuid) {
			statements.push(macro __column.ServerGeneratedGuid = true);
		}
		if (column.maxLength != null) {
			statements.push(macro __column.MaxLength = $v{column.maxLength});
		}
		if (column.precision != null) {
			statements.push(macro __column.Precision = $v{column.precision});
		}
		if (column.scale != null) {
			statements.push(macro __column.Scale = $v{column.scale});
		}
		if (column.comment != null) {
			statements.push(macro __column.Comment = $v{column.comment});
		}
		if (column.defaultTree != null) {
			statements.push(macro __column.SetDefaultValue(${column.defaultTree}));
			statements.push(macro __column.DeclaredDefault = ${column.declaredDefault});
		}
		statements.push(macro __column);
		return {expr: EBlock(statements), pos: Context.currentPos()};
	}

	// ---- naming ----------------------------------------------------------------------------------

	/** The entity's `@tableName`, else the type's own name. */
	public static function TableNameOf(row:ClassType):String {
		for (name in ["tableName", "table"]) {
			switch row.meta.extract(name) {
				case [{params: [{expr: EConst(CString(given, _))}]}] | [{params: [{expr: EConst(CString(given, _))}, _]}]: return given;
				case _:
			}
		}
		return row.name;
	}

	/** The schema the table lives in — `@tableName("x", "dbo")` or `@tableSchema("dbo")` — or null. */
	public static function SchemaOf(row:ClassType):Null<String> {
		for (name in ["tableName", "table"]) {
			switch row.meta.extract(name) {
				case [{params: [_, {expr: EConst(CString(schema, _))}]}]: return schema;
				case _:
			}
		}
		return switch row.meta.extract("tableSchema") {
			case [{params: [{expr: EConst(CString(schema, _))}]}]: schema;
			case _: null;
		}
	}

	/** A field's `@columnName`, else the field's own name. */
	public static function ColumnNameOf(field:ClassField):String {
		for (name in ["columnName", "column"]) {
			switch field.meta.extract(name) {
				case [{params: [{expr: EConst(CString(given, _))}]}]: return given;
				case _:
			}
		}
		return field.name;
	}

	/** The column an entity is keyed by: the field saying so, else the `id` convention, else `id`. */
	public static function PrimaryKeyColumnOf(row:ClassType):String {
		for (field in ColumnFields(row)) {
			if (IsPrimaryKey(field, row)) {
				return ColumnNameOf(field);
			}
		}
		return "id";
	}

	static function IsPrimaryKey(field:ClassField, row:ClassType):Bool {
		if (field.meta.has("columnPrimaryKey") || field.meta.has("key")) {
			return true;
		}
		final name = field.name.toLowerCase();
		return name == "id" || name == (row.name + "Id").toLowerCase();
	}

	/** The public variables of a class, which are what map to columns. */
	public static function ColumnFields(row:ClassType):Array<ClassField> {
		return [
			for (field in SchemaMembers.FieldsOf(row))
				if (field.isPublic && field.kind.match(FVar(AccNormal | AccNo, _)) && !field.meta.has("notMapped")) field
		];
	}

	// ---- types -----------------------------------------------------------------------------------

	/** What a field's type says about the column: its kind, and whether it takes null. */
	public static function Classify(type:Type):{type:String, nullable:Bool, isGuid:Bool, isInteger:Bool, nested:Null<ClassType>, skip:Bool} {
		var nullable = false;
		var held = type;
		while (true) {
			switch held {
				case TAbstract(_.get() => {name: "Null", pack: []}, [inner]) | TType(_.get() => {name: "Null", pack: []}, [inner]):
					nullable = true;
					held = inner;
				case TType(t, params):
					held = held.follow(true);
				case TLazy(f):
					held = f();
				case _:
					break;
			}
		}

		return switch held {
			case TAbstract(a, _):
				final abs = a.get();
				switch abs.name {
					case "Int": Kind("Int", nullable, false, true);
					case "Float": Kind("Double", nullable);
					case "Bool": Kind("Boolean", nullable);
					case "Guid": Kind("Guid", nullable, true);
					case "Decimal": Kind("Decimal", nullable);
					case "SmallInt": Kind("SmallInt", nullable, false, true);
					case "TinyInt": Kind("TinyInt", nullable, false, true);
					case "Single": Kind("Float", nullable);
					case "TimeSpan": Kind("Time", nullable);
					case "DateTimeOffset": Kind("DateTimeOffset", nullable);
					case "Char": Kind("Char", nullable);
					case "Int64": Kind("BigInt", nullable, false, true);
					case "SqlDate": Kind("Date", nullable);
					case _ if (abs.meta.has(":enum")): Kind("Int", nullable);
					case _:
						final underlying = Classify(abs.type);
						underlying.nullable = nullable || underlying.nullable;
						underlying;
				}
			case TInst(c, _):
				final cls = c.get();
				switch SchemaMembers.PathOf(cls) {
					case "String": Kind("VarChar", true);
					case "Date": Kind("DateTime", nullable);
					case "haxe.io.Bytes": Kind("VarBinary", true);
					case "Array" | "List" | "haxe.ds.List": Kind("Unknown", nullable, false, false, null, true);
					case _: Kind("Unknown", true, false, false, cls);
				}
			case TEnum(_, _): Kind("Int", nullable);
			case _: Kind("Unknown", nullable);
		}
	}

	static function Kind(type:String, nullable:Bool, isGuid:Bool = false, isInteger:Bool = false, ?nested:ClassType, skip:Bool = false) {
		return {type: type, nullable: nullable, isGuid: isGuid, isInteger: isInteger, nested: nested, skip: skip};
	}

	/** The `DatabaseColumnType` a type maps to, as the C# `ToDatabaseColumnType` answers it. */
	public static function ColumnTypeOf(type:Type):String {
		return Classify(type).type;
	}

	// ---- columns ---------------------------------------------------------------------------------

	/** Every column of the table, in declaration order, with what its field and metadata say. */
	public static function ColumnSpecs(row:ClassType, pos:Position):Array<ColumnSpec> {
		final columns:Array<ColumnSpec> = [];
		Collect(row, row, [], [], columns, pos);
		return columns;
	}

	static function Collect(row:ClassType, entity:ClassType, prefix:Array<String>, visited:Array<String>, into:Array<ColumnSpec>, pos:Position):Void {
		for (field in ColumnFields(row)) {
			final kind = Classify(field.type);
			if (kind.skip) {
				continue;
			}

			if (kind.nested != null) {
				// A member that is an object is its members' columns, named for the path to them.
				final path = SchemaMembers.PathOf(kind.nested);
				if (visited.indexOf(path) >= 0) {
					Context.error('${row.name}.${field.name} contains itself', pos);
				}
				Collect(kind.nested, entity, prefix.concat([ColumnNameOf(field)]), visited.concat([path]), into, pos);
				continue;
			}

			if (kind.type == "Unknown") {
				throw new Refused('${row.name}.${field.name} has no column type; declare one it can be stored as, or leave it out with @notMapped');
			}

			final topLevel = prefix.length == 0;
			final name = prefix.concat([ColumnNameOf(field)]).join("_");
			final primaryKey = topLevel && IsPrimaryKey(field, entity);
			final key = PrimaryKeyMeta(field);
			final generation = key.generation != null ? key.generation : (kind.isGuid ? "ClientGenerated" : "ServerGenerated");

			final autoIncrement = kind.isInteger && (key.present
				? (generation == "ServerGenerated" && key.autoIncrement)
				: (field.meta.has("databaseGenerated") || primaryKey));

			final column:ColumnSpec = {
				name: name,
				field: field,
				type: kind.type,
				nullable: kind.nullable && !field.meta.has("required"),
				autoIncrement: autoIncrement,
				identity: key.identity,
				serverGuid: kind.isGuid && primaryKey && generation == "ServerGenerated",
				isGuid: kind.isGuid,
				maxLength: null,
				precision: null,
				scale: null,
				comment: null,
				defaultTree: null,
				declaredDefault: null,
				primaryKey: primaryKey,
				generation: generation,
				foreignKey: null,
				unique: field.meta.has("columnUnique") || field.meta.has("unique")
			};

			ApplyColumnMeta(field, column, entity);

			if (topLevel) {
				column.foreignKey = ForeignKeyOf(field, entity, pos);
			}

			if (!column.autoIncrement && !column.serverGuid) {
				DeclaredDefault(field, column);
			}

			into.push(column);
		}
	}

	/**
		What `@columnPrimaryKey` says. Haxe keeps a metadata's parameters as constants, so the
		attribute's properties are written as one: `@columnPrimaryKey({generation: "ClientGenerated",
		autoIncrement: false, identity: "Always"})`, or the generation alone, `@columnPrimaryKey("ClientGenerated")`.
	**/
	static function PrimaryKeyMeta(field:ClassField):{present:Bool, generation:Null<String>, autoIncrement:Bool, identity:String} {
		final result = {present: false, generation: null, autoIncrement: true, identity: "ByDefault"};
		for (entry in field.meta.extract("columnPrimaryKey")) {
			result.present = true;
			for (param in entry.params) {
				for (option in Options(param)) {
					switch option.name {
						case "generation": result.generation = option.value;
						case "autoIncrement": result.autoIncrement = option.value == "true";
						case "identity": result.identity = option.value;
						case "": result.generation = option.value;
						case _: Context.error("@columnPrimaryKey takes generation, autoIncrement or identity", param.pos);
					}
				}
			}
		}
		return result;
	}

	/**
		A metadata parameter's options: `{name: "x", other: true}` is each pair; a bare constant is
		one unnamed option; `name = value` is read too, for where the metadata is written `@:`-prefixed.
	**/
	static function Options(param:Expr):Array<{name:String, value:String}> {
		return switch param.expr {
			case EObjectDecl(fields): [for (f in fields) {name: f.field, value: ConstText(f.expr)}];
			case EBinop(OpAssign, {expr: EConst(CIdent(name))}, value): [{name: name, value: ConstText(value)}];
			case _: [{name: "", value: ConstText(param)}];
		}
	}

	static function ConstText(e:Expr):String {
		return switch e.expr {
			case EConst(CString(s, _)): s;
			case EConst(CIdent(s)): s;
			case EConst(CInt(v, _)) | EConst(CFloat(v, _)): v;
			case EField(_, name, _): name;
			case _: Context.error("Expected a constant", e.pos);
		}
	}

	/** The annotations that amend the column: width, exactness, unbounded text, a comment. */
	static function ApplyColumnMeta(field:ClassField, column:ColumnSpec, entity:ClassType):Void {
		switch field.meta.extract("columnNullable") {
			case [{params: [{expr: EConst(CIdent(value))}]}]: column.nullable = value == "true";
			case _:
		}

		for (name in ["columnMaxLength", "maxLength", "stringLength"]) {
			switch field.meta.extract(name) {
				case [{params: [{expr: EConst(CInt(length, _))}]}] if (column.maxLength == null): column.maxLength = Std.parseInt(length);
				case _:
			}
		}

		switch field.meta.extract("columnText") {
			case [entry]:
				if (field.meta.has("columnMaxLength")) {
					throw new Refused('${entity.name}.${field.name} says both [ColumnText] and [ColumnMaxLength]: text is unbounded, and a maximum length bounds it. Say one or the other.');
				}
				var unicode = false;
				for (param in entry.params) {
					for (option in Options(param)) {
						if ((option.name == "unicode" || option.name == "") && (option.value == "true" || option.value == "unicode")) {
							unicode = true;
						}
					}
				}
				column.type = unicode ? "NText" : "Text";
				column.maxLength = null;
			case _:
		}

		switch field.meta.extract("dbColumnPrecision") {
			case [{params: [{expr: EConst(CInt(precision, _))}, {expr: EConst(CInt(scale, _))}]}]:
				GuardPrecision(Std.parseInt(precision), Std.parseInt(scale), '${entity.name}.${column.name}');
				column.precision = Std.parseInt(precision);
				column.scale = Std.parseInt(scale);
			case _:
		}

		switch field.meta.extract("columnTypeName") {
			case [{params: [{expr: EConst(CString(typeName, _))}]}]:
				throw new Refused('${entity.name}.${field.name} names a column type of its own, "$typeName", which belongs to one dialect. Say what the column is instead: for a decimal\'s exactness @dbColumnPrecision (DbColumnPrecision), for a string\'s length @columnMaxLength.');
			case _:
		}

		switch field.meta.extract("columnComment") {
			case [{params: [{expr: EConst(CString(comment, _))}]}]: column.comment = comment;
			case _:
		}
	}

	/** Refuses a precision no database would take, naming what declared it. */
	public static function GuardPrecision(precision:Int, scale:Int, declaredBy:String):Void {
		if (precision < 1) {
			throw new Refused('$declaredBy asks for a decimal of $precision digits. A column keeps at least one.');
		}
		if (scale < 0) {
			throw new Refused('$declaredBy asks for $scale digits after the point. A column keeps none or more.');
		}
		if (scale > precision) {
			throw new Refused('$declaredBy asks for $scale digits after the point out of $precision in total. A decimal cannot keep more after the point than it keeps altogether.');
		}
	}

	/** `@columnForeignKey(Author)`, else `@columnForeignKey(Author, "id", onDelete = Cascade)`. */
	static function ForeignKeyOf(field:ClassField, entity:ClassType, pos:Position):Null<{table:String, column:String, onDelete:String, onUpdate:String, index:Bool}> {
		final entries = field.meta.extract("columnForeignKey").concat(field.meta.extract("dbColumnForeignKey"));
		if (entries.length == 0) {
			return null;
		}
		final params = entries[0].params;
		if (params.length == 0) {
			Context.error("@columnForeignKey names the entity it references", entries[0].pos);
		}
		final referenced = ReferencedClass(params[0], entity);
		final result = {table: TableNameOf(referenced), column: null, onDelete: "NoAction", onUpdate: "NoAction", index: true};
		for (param in params.slice(1)) {
			for (option in Options(param)) {
				switch option.name {
					case "": result.column = option.value;
					case "column" | "referencedColumn": result.column = option.value;
					case "onDelete": result.onDelete = option.value;
					case "onUpdate": result.onUpdate = option.value;
					case "index": result.index = option.value == "true";
					case _: Context.error("@columnForeignKey takes the referenced column, onDelete, onUpdate or index", param.pos);
				}
			}
		}
		if (result.column == null) {
			result.column = PrimaryKeyColumnOf(referenced);
		}
		return result;
	}

	/**
		The class a metadata parameter names — `@columnForeignKey(Unit)` or `@columnForeignKey("sample.Unit")` —
		looked for beside the entity when not found as written.
	**/
	static function ReferencedClass(named:Expr, entity:ClassType):ClassType {
		final path = switch named.expr {
			case EConst(CString(given, _)): given;
			case _: named.toString();
		}
		for (candidate in [path, entity.module + "." + path, entity.pack.concat([path]).join(".")]) {
			final resolved = try Context.getType(candidate) catch (e:Dynamic) null;
			if (resolved == null) {
				continue;
			}
			switch resolved.follow() {
				case TInst(t, _): return t.get();
				case _:
			}
		}
		return Context.error('$path is not a class this can reference', named.pos);
	}

	/**
		A property initializer is a default the entity already states: `= 42` declares `DEFAULT 42`.
		Read narrowly — a constant, and not the type's own zero, which says nothing.
	**/
	static function DeclaredDefault(field:ClassField, column:ColumnSpec):Void {
		final initializer = field.expr();
		if (initializer == null) {
			return;
		}
		final constant = ConstantIn(initializer);
		if (constant == null) {
			return;
		}
		column.defaultTree = switch constant {
			case TInt(0) | TBool(false): return;
			case TFloat(f) if (Std.parseFloat(f) == 0): return;
			case TInt(v): macro codequery.sqlexpressions.Expr.constInt($v{v});
			case TFloat(f): macro codequery.sqlexpressions.Expr.constFloat($v{Std.parseFloat(f)});
			case TString(s): macro codequery.sqlexpressions.Expr.constString($v{s});
			case TBool(b): macro codequery.sqlexpressions.Expr.constBool($v{b});
			case _: return;
		}
		// In the entity's own terms — an enum member rather than its number — for a conversion to carry over.
		column.declaredDefault = Context.getTypedExpr(initializer);
	}

	/** The constant a typed initializer is, through casts and an enum abstract's member, or null. */
	static function ConstantIn(e:TypedExpr):Null<TConstant> {
		return switch e.expr {
			case TConst(c): c;
			case TCast(inner, _) | TMeta(_, inner) | TParenthesis(inner): ConstantIn(inner);
			case TUnop(OpNeg, false, inner):
				switch ConstantIn(inner) {
					case TInt(v): TInt(-v);
					case TFloat(f): TFloat("-" + f);
					case _: null;
				}
			case TField(_, FStatic(_, cf)):
				final member = cf.get().expr();
				member == null ? null : ConstantIn(member);
			case _: null;
		}
	}
	#end
}

#if macro
/** What one column comes out as, before it is written as code. */
typedef ColumnSpec = {
	name:String,
	field:Null<ClassField>,
	type:String,
	nullable:Bool,
	autoIncrement:Bool,
	identity:String,
	serverGuid:Bool,
	isGuid:Bool,
	maxLength:Null<Int>,
	precision:Null<Int>,
	scale:Null<Int>,
	comment:Null<String>,
	defaultTree:Null<Expr>,
	declaredDefault:Null<Expr>,
	primaryKey:Bool,
	generation:String,
	foreignKey:Null<{table:String, column:String, onDelete:String, onUpdate:String, index:Bool}>,
	unique:Bool
};


/** A declaration the inspector refuses, said at runtime as C# says it, so a test can catch it. */
class Refused {
	public final message:String;

	public function new(message:String) {
		this.message = message;
	}
}
#end
