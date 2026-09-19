package codequery;

import codequery.sqlexpressions.ColumnsBuilder;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	A table or a query over an entity, by its type alone — no schema declaring it.

	The C# tests do `new SelectQuery<Book>()` and `new Query<Author>("authors")`. Haxe cannot read
	a type parameter at runtime, so these are macros: the entity is named where the call is made,
	and its table name read off it while compiling, as `DbTable.of()` does for a schema member.
**/
class Query {
	/** A table for an entity, named for it: `Query.table(Author)`, or `Query.table(Author, "authors")`. */
	public static macro function table(entity:Expr, ?name:Expr):Expr {
		return Table(entity, name);
	}

	/** A SELECT over an entity, named for it: `Query.select(Book)`. */
	public static macro function select(entity:Expr, ?name:Expr):Expr {
		final made = Table(entity, name);
		return macro $made.From();
	}

	#if macro
	/** One macro may not call another, so what both do is here for both to call. */
	static function Table(entity:Expr, name:Null<Expr>):Expr {
		final type = Context.getType(EntityPath(entity));
		final tableName = name != null && !name.expr.match(EConst(CIdent("null")))
			? name
			: macro $v{ColumnsBuilder.TableNameOfType(type)};
		final path = TypeOf(type);
		return macro(new codequery.DbTable<$path>(new codequery.QualifiedTableName($tableName)) : codequery.DbTable<$path>);
	}

	static function EntityPath(entity:Expr):String {
		return switch entity.expr {
			case EConst(CIdent(name)): name;
			case EField(_, _, _): new haxe.macro.Printer().printExpr(entity);
			case _: Context.error("Name the entity type, e.g. Query.select(Book)", entity.pos);
		}
	}

	static function TypeOf(type:haxe.macro.Type):ComplexType {
		return haxe.macro.TypeTools.toComplexType(type);
	}
	#end
}
