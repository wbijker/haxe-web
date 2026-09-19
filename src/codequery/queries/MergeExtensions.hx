package codequery.queries;

import codequery.sqlexpressions.ExpressionConverter;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.TypeTools;
#end

/** The clauses of `IMergeInto` and `IMergeBuilder`. */
class MergeExtensions {
	/** Sets the source row set and the `ON` match condition. */
	public static macro function Using(self:Expr, source:Expr, on:Expr):Expr {
		final rows = [ExpressionConverter.EntitiesOf(self)[0], ExpressionConverter.EntityOf(source)];
		final condition = ExpressionConverter.Convert(on, rows);
		final statement = macro(cast $source : codequery.queries.SelectQueryImpl).ToExpression();
		return Answering(macro ${Impl(self)}.UsingSource($statement, $condition), rows);
	}

	/** `WHEN MATCHED [AND condition] THEN UPDATE SET …`, from a structure naming the columns. */
	public static macro function WhenMatchedUpdate(self:Expr, set:Expr, ?condition:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final selection = ExpressionConverter.ConvertProjection(set, rows).selection;
		final refined = Condition(condition, rows);
		return Answering(macro ${Impl(self)}.MatchedUpdate($selection, $refined), rows);
	}

	/** `WHEN MATCHED [AND condition] THEN DELETE`. */
	public static macro function WhenMatchedDelete(self:Expr, ?condition:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final refined = Condition(condition, rows);
		return Answering(macro ${Impl(self)}.MatchedDelete($refined), rows);
	}

	/** `WHEN NOT MATCHED [AND condition] THEN INSERT (…) VALUES (…)`, from a structure naming the columns. */
	public static macro function WhenNotMatchedInsert(self:Expr, insert:Expr, ?condition:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final selection = ExpressionConverter.ConvertProjection(insert, rows).selection;
		final refined = Condition(condition, rows);
		return Answering(macro ${Impl(self)}.NotMatchedInsert($selection, $refined), rows);
	}

	#if macro
	static function Condition(condition:Null<Expr>, rows:Array<haxe.macro.Type>):Expr {
		return ExpressionConverter.Omitted(condition) ? macro null : ExpressionConverter.Convert(condition, rows);
	}

	static function Answering(built:Expr, rows:Array<haxe.macro.Type>):Expr {
		final queryType = TPath({
			pack: ["codequery", "queries"],
			name: "IMergeBuilder",
			params: [for (row in rows) TPType(row.toComplexType())]
		});
		return macro(cast $built : $queryType);
	}

	static function Impl(self:Expr):Expr {
		return macro(cast $self : codequery.queries.MergeBuilderImpl);
	}
	#end
}
