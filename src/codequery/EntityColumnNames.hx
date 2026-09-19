package codequery;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
#end

/**
	How an entity's fields map to its columns — `@columnName` is declarative, so an entity that
	names its columns on the type needs no registration for a query to name them the same way.

	C#'s `EntityColumnNames` answers at runtime by reflection; here the same questions are answered
	while compiling, from the type named at the call site, since that is where the port reads every
	column name from.
**/
class EntityColumnNames {
	/** The column a field is stored in: its `@columnName`, else its own name. */
	public static macro function resolveColumn(entity:Expr, field:Expr):Expr {
		final row = Entity(entity);
		final name = Literal(field);
		for (f in row.fields.get()) {
			if (f.name == name) {
				return macro $v{codequery.sqlexpressions.ColumnsBuilder.ColumnNameOf(f)};
			}
		}
		return Context.error('${row.name} has no field "$name"', field.pos);
	}

	/** The field a column is read back onto: the one whose `@columnName` it is, else the one it is named after. */
	public static macro function resolveField(entity:Expr, column:Expr):Expr {
		final row = Entity(entity);
		final name = Literal(column);
		for (f in row.fields.get()) {
			if (codequery.sqlexpressions.ColumnsBuilder.ColumnNameOf(f) == name) {
				return macro $v{f.name};
			}
		}
		return macro $v{name};
	}

	/** Whether any field of the entity is stored under a name other than its own. */
	public static macro function isMapped(entity:Expr):Expr {
		final row = Entity(entity);
		for (f in row.fields.get()) {
			if (codequery.sqlexpressions.ColumnsBuilder.ColumnNameOf(f) != f.name) {
				return macro true;
			}
		}
		return macro false;
	}

	#if macro
	static function Entity(entity:Expr):ClassType {
		final path = switch entity.expr {
			case EConst(CIdent(name)): name;
			case EField(_, _, _): new haxe.macro.Printer().printExpr(entity);
			case _: Context.error("Name the entity type, e.g. EntityColumnNames.resolveColumn(Book, \"title\")", entity.pos);
		}
		return switch Context.getType(path).follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', entity.pos);
		}
	}

	static function Literal(e:Expr):String {
		return switch e.expr {
			case EConst(CString(s, _)): s;
			case _: Context.error("Expected a name written out here", e.pos);
		}
	}
	#end
}
