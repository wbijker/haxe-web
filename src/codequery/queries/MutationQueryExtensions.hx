package codequery.queries;

import codequery.sqlexpressions.ExpressionConverter;
#if macro
import haxe.macro.Expr;
#end

/**
	The clauses of `IUpdateQuery` and `IDeleteQuery`.

	Written once for both, as `SelectQueryExtensions` is written once for every arity: each reads
	the row it is over from the static type of the query it was called on.
**/
class MutationQueryExtensions {
	/**
		`SET column = value`.

		C# has two of these — one taking a value, one taking an expression over the row. A macro
		sees which it was given, so there is one here: a lambda is an expression, anything else is
		a value.
	**/
	public static macro function Set(self:Expr, column:Expr, value:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		// An owned object assigned whole is every column it is spread over, assigned one by one.
		final spread = ExpressionConverter.ConvertObjectAssignment(column, value, rows);
		if (spread != null) {
			var assigned = Impl(self);
			for (each in spread) {
				assigned = macro $assigned.SetColumn(${each.column}, ${each.value});
			}
			return ExpressionConverter.AnsweringMutation(assigned, self);
		}
		// A column is assigned on the target, so it names that row alone; what it is assigned may
		// name every row the statement has.
		final target = ExpressionConverter.ConvertColumn(column, [rows[0]]);
		final assigned = ExpressionConverter.ConvertValue(value, rows);
		return ExpressionConverter.AnsweringMutation(macro ${Impl(self)}.SetColumn($target, $assigned), self);
	}

	/** `WHERE <predicate>`. Called again, it adds another condition with AND. */
	public static macro function Where(self:Expr, predicate:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final condition = ExpressionConverter.Convert(predicate, rows);
		return ExpressionConverter.AnsweringMutation(macro ${Impl(self)}.WhereCondition($condition), self);
	}

	/** `RETURNING <projection>` — what the statement hands back for each row it touched. */
	public static macro function Returning(self:Expr, selector:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final projected = ExpressionConverter.ConvertProjection(selector, rows);
		final selection = projected.selection;
		return ExpressionConverter.AnsweringMutation(macro ${Impl(self)}.ReturningProjection($selection), self);
	}

	/** A clause only sometimes wanted, said in the chain: `.Conditional(onlyOpen, q -> q.Where(…))`. */
	public static macro function Conditional(self:Expr, condition:Expr, then:Expr, ?otherwise:Expr):Expr {
		return codequery.sqlexpressions.LambdaCalls.Conditional(self, condition, then, otherwise);
	}

	#if macro
	static function Impl(self:Expr):Expr {
		return macro(cast $self : codequery.queries.MutationQueryImpl);
	}
	#end
}
