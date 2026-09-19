package codequery.queries;

import codequery.sqlexpressions.ExpressionConverter;
#if macro
import haxe.macro.Expr;
#end

/** The clauses of `IInsertQuery`. */
class InsertQueryExtensions {
	/**
		`ON CONFLICT (<columns>)` — which columns decide that a row is already there. Without a
		following `Update`, the insert leaves that row alone.
	**/
	public static macro function OnConflict(self:Expr, columns:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final named = ExpressionConverter.ConvertColumnNames(columns, rows);
		return ExpressionConverter.AnsweringInsert(macro ${Impl(self)}.ConflictOn($named), self);
	}

	/** `DO UPDATE SET column = <value>` — what a row already there is set to instead. */
	public static macro function Update(self:Expr, column:Expr, value:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final target = ExpressionConverter.ConvertColumn(column, rows);
		final assigned = ExpressionConverter.ConvertValue(value, rows);
		return ExpressionConverter.AnsweringInsert(macro ${Impl(self)}.ConflictUpdate($target, $assigned), self);
	}

	/** `OVERRIDING SYSTEM VALUE` / `USER VALUE` — whether a generated column may be written. */
	public static macro function Overriding(self:Expr, mode:Expr):Expr {
		return ExpressionConverter.AnsweringInsert(macro ${Impl(self)}.Override($mode), self);
	}

	/** `RETURNING <projection>` — what the statement hands back for each row it wrote. */
	public static macro function Returning(self:Expr, selector:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final projected = ExpressionConverter.ConvertProjection(selector, rows);
		final selection = projected.selection;
		return ExpressionConverter.AnsweringInsert(macro ${Impl(self)}.ReturningProjection($selection), self);
	}

	#if macro
	static function Impl(self:Expr):Expr {
		return macro(cast $self : codequery.queries.InsertQueryImpl);
	}
	#end
}
