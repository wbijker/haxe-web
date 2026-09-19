package codequery.migrations;

#if macro
import codequery.sqlexpressions.ColumnsBuilder;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
#end

/**
	Reads the schema off the entities, while compiling.

	C# reflects over the schema class at runtime to find what it declares. Here the same walk
	happens during compilation — the same walk `ColumnsBuilder` does for a query's columns, so a
	column of the schema and a column of a query cannot disagree about what a table has.
**/
class SchemaBuilder {
	/**
		The schema a class declares, from its `DbTable` and `DbView` members.

		A view is described but not built: it is a query given a name, and what creates one is the
		query, not a list of columns.
	**/
	public static macro function Of(schema:Expr):Expr {
		final declared = switch Context.typeof(schema).follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not a schema class', schema.pos);
		}

		final tables:Array<Expr> = [];
		final views:Array<Expr> = [];
		for (field in declared.fields.get()) {
			if (!field.isPublic) {
				continue;
			}
			if (IsView(field.type)) {
				views.push(ViewOf(field));
				continue;
			}
			final entity = EntityOfTable(field.type);
			if (entity == null) {
				continue;
			}
			tables.push(TableOf(entity, field.pos));
		}

		final list = {expr: EArrayDecl(tables), pos: schema.pos};
		final viewList = {expr: EArrayDecl(views), pos: schema.pos};
		// A view's definition is a query the member holds, so the schema instance is read for it —
		// once, whatever expression named it.
		return macro {
			final declared = $schema;
			new codequery.migrations.DatabaseSchema($list, $v{declared.name}, 1, $viewList);
		};
	}

	#if macro
	/** Whether a member is a `DbView<T>`, or a class of its own extending one. */
	static function IsView(type:Type):Bool {
		return switch type.follow() {
			case TInst(t, _): ExtendsView(t.get());
			case _: false;
		}
	}

	static function ExtendsView(row:ClassType):Bool {
		if (row.name == "DbView" && row.pack.join(".") == "codequery") {
			return true;
		}
		return row.superClass != null && ExtendsView(row.superClass.t.get());
	}

	/**
		The view a member declares, migrated as its `@dbMigration(<strategy>)` says — on the member,
		or on the view's own class where it has one — and replaced in place where nothing says.
	**/
	static function ViewOf(field:ClassField):Expr {
		final name = field.name;
		final strategy = StrategyOf(field.meta.extract("dbMigration"));
		final declaredOnClass = switch field.type.follow() {
			case TInst(t, _): StrategyOf(t.get().meta.extract("dbMigration"));
			case _: null;
		}
		final chosen = strategy != null ? strategy : (declaredOnClass != null ? declaredOnClass : macro null);
		return macro codequery.migrations.DatabaseViewDefinition.Of(declared.$name, $chosen);
	}

	static function StrategyOf(meta:Array<MetadataEntry>):Null<Expr> {
		// Written as a string — `@dbMigration("DropThenCreate")` — since metadata kept at runtime
		// holds constants only; an identifier is taken too, where the metadata allows it.
		return switch meta {
			case [{params: [{expr: EConst(CIdent(strategy) | CString(strategy, _))}]}]:
				macro $p{["codequery", "migrations", "DbMigrationStrategy", strategy]};
			case _: null;
		}
	}

	/** The row type of a `DbTable<T>`, or null for a member that is not one. */
	static function EntityOfTable(type:Type):Null<Type> {
		return switch type.follow() {
			case TInst(t, [row]) if (t.get().name == "DbTable"): row;
			case _: null;
		}
	}

	static function TableOf(entity:Type, pos:Position):Expr {
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', pos);
		}

		final columns:Array<Expr> = [];
		ColumnsOf(row, [], [], columns, pos);

		final list = {expr: EArrayDecl(columns), pos: pos};
		return macro new codequery.migrations.DatabaseTableDefinition(
			$v{ColumnsBuilder.TableNameOf(row)}, $list);
	}

	/** The same walk `ColumnsBuilder` does, so a schema and a query agree about a table. */
	static function ColumnsOf(row:ClassType, member:Array<String>, visited:Array<String>,
			into:Array<Expr>, pos:Position):Void {
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
				ColumnsOf(nested, member.concat([ColumnsBuilder.ColumnNameOf(field)]),
					visited.concat([path]), into, pos);
				continue;
			}

			final name = member.concat([ColumnsBuilder.ColumnNameOf(field)]).join(ColumnsBuilder.Separator);
			final type = ColumnsBuilder.SqlTypeOfField(field);
			// A key is the one column the database fills in, and a nested member is never one.
			final key = member.length == 0 && (field.name == "id" || field.meta.has("primaryKey"));
			into.push(macro new codequery.migrations.DatabaseColumnDefinition(
				$v{name}, $type, $v{IsNullable(field)}, $v{key}));
		}
	}

	/**
		Whether a column takes a null.

		`Null<T>` says so, and so does `@columnNullable(false)` saying the opposite — C# writes that
		attribute on a string, which is the one type whose Haxe spelling does not already say it.
	**/
	static function IsNullable(field:ClassField):Bool {
		final stated = switch field.meta.extract("columnNullable") {
			case [{params: [{expr: EConst(CIdent(v))}]}]: v == "true";
			case _: null;
		}
		if (stated != null) {
			return stated;
		}
		return switch field.type {
			case TType(t, _) if (t.get().name == "Null"): true;
			case TAbstract(t, _) if (t.get().name == "Null"): true;
			// A string holds a null whether or not it is spelled that way.
			case TInst(t, _) if (t.get().name == "String"): true;
			case _: false;
		}
	}
	#end
}
