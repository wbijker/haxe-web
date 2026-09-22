package codequery.queries;

import codequery.sqlexpressions.ColumnsBuilder;
import codequery.sqlexpressions.ExpressionConverter;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.TypeTools;
#end

/**
	A DELETE begun from the query that finds its rows — C#'s `ISelectQuery<TSource>.Delete<TTarget>(on)`:
	`DELETE FROM <target> USING (<this query>) WHERE <on>`, the condition naming the target's row
	first and the query's second.
**/
class MutationFromQuery {
	#if macro
	public static function Delete(self:Expr, target:Expr, condition:Expr):Expr {
		final name = switch target.expr {
			case EConst(CIdent(name)): name;
			case EField(_, _, _): new haxe.macro.Printer().printExpr(target);
			case _: Context.error("Name the table's entity type, e.g. .Delete(Book, (t, s) -> t.id == s.id)", target.pos);
		}
		final entity = Context.getType(name);
		final rows = [entity, ExpressionConverter.EntityOf(self)];
		final on = ExpressionConverter.ConvertCallback(condition, rows);
		final table = macro new codequery.QualifiedTableName($v{ColumnsBuilder.TableNameOfType(entity)});
		final shape = ExpressionConverter.ShapeOf(entity);
		final source = macro(cast $self : codequery.queries.SelectQueryImpl);

		final queryType = TPath({
			pack: ["codequery", "queries"],
			name: "IDeleteQuery2",
			params: [for (row in rows) TPType(row.toComplexType())]
		});
		return macro(cast codequery.queries.MutationQueryImpl.DeletingUsing($table, $source, $shape).Where($on) : $queryType);
	}
	#end
}
