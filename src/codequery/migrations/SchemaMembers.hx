package codequery.migrations;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
using haxe.macro.ExprTools;

/**
	What the macros here have to know about a class while compiling: how it is named, and which of
	its members are tables.

	C# reads all of this by reflection at runtime. Haxe reads it once, here, and every macro that
	needs a type's name or its table members asks this rather than working it out again.
**/
class SchemaMembers {
	/** The type an expression names — `Book`, or `pack.Book` — or the type of the expression. */
	public static function TypeOf(e:Expr):Type {
		final path = DottedPath(e);
		if (path != null) {
			try {
				return Context.getType(path);
			} catch (_:Dynamic) {}
		}
		return Context.typeof(e);
	}

	/** The class an expression names, or is an instance of. */
	public static function ClassTypeOf(e:Expr):ClassType {
		return switch TypeOf(e).follow() {
			case TInst(t, _): t.get();
			// `Book` on its own types as `Class<Book>`.
			case TAnonymous(a):
				switch a.get().status {
					case AClassStatics(t): t.get();
					case _: Context.error('${e.toString()} is not a class', e.pos);
				}
			case t: Context.error('${t.toString()} is not a class', e.pos);
		}
	}

	/** The class path — `entities.Book` — that a class is known by at runtime. */
	public static function PathOf(c:ClassType):String {
		return c.pack.concat([c.name]).join(".");
	}

	public static function ClassPathOf(e:Expr):String {
		return PathOf(ClassTypeOf(e));
	}

	public static function ClassNameOf(e:Expr):String {
		return ClassTypeOf(e).name;
	}

	/**
		The path that names a class in code from anywhere its module is visible — `pack.Module.Type`
		for a type declared beside the module's own.
	**/
	public static function QualifiedPath(c:ClassType):Array<String> {
		final modulePath = c.module.split(".");
		return modulePath[modulePath.length - 1] == c.name ? modulePath : modulePath.concat([c.name]);
	}

	/** The same, as a type path `new` can take. */
	public static function TypePathOf(c:ClassType):TypePath {
		final modulePath = c.module.split(".");
		final moduleName = modulePath[modulePath.length - 1];
		// A private type is visible by its own name, and only where it is declared.
		if (c.isPrivate) {
			return {pack: [], name: c.name};
		}
		return moduleName == c.name
			? {pack: c.pack, name: c.name}
			: {pack: modulePath.slice(0, modulePath.length - 1), name: moduleName, sub: c.name};
	}

	/** The same, as an expression naming the class. */
	public static function ClassExpr(c:ClassType):Expr {
		return c.isPrivate ? macro $i{c.name} : macro $p{QualifiedPath(c)};
	}

	static function DottedPath(e:Expr):Null<String> {
		return switch e.expr {
			case EConst(CIdent(name)) if (name.charAt(0).toUpperCase() == name.charAt(0)): name;
			case EField(owner, name, _):
				final head = DottedPath(owner);
				head == null ? null : '$head.$name';
			case EParenthesis(inner): DottedPath(inner);
			case _: null;
		}
	}

	/** The fields a class has, its ancestors' first, as reflection lists them. */
	public static function FieldsOf(c:ClassType):Array<ClassField> {
		final inherited = c.superClass == null ? [] : FieldsOf(c.superClass.t.get());
		return inherited.concat(c.fields.get());
	}

	/** The row type of a `DbTable<T>`, or of a class deriving from one, or null for anything else. */
	public static function EntityOfTable(type:Type):Null<Type> {
		return switch type.follow() {
			case TInst(t, params):
				final c = t.get();
				if (c.name == "DbTable" && c.pack.join(".") == "codequery") {
					params[0];
				} else if (c.superClass != null) {
					EntityOfTable(TInst(c.superClass.t, c.superClass.params));
				} else {
					null;
				}
			case _: null;
		}
	}

	/** The table members of a schema class: each `DbTable<T>` field, with its entity. */
	public static function TablesOf(schema:ClassType):Array<{field:ClassField, entity:Type, row:ClassType}> {
		final tables = [];
		for (field in FieldsOf(schema)) {
			if (!field.isPublic || !field.kind.match(FVar(_, _))) {
				continue;
			}
			final entity = EntityOfTable(field.type);
			if (entity == null) {
				continue;
			}
			final row = switch entity.follow() {
				case TInst(t, _): t.get();
				case _: continue;
			}
			tables.push({field: field, entity: entity, row: row});
		}
		return tables;
	}
}
#end
