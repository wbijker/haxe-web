package codequery.queries;

import codequery.sqlexpressions.ExpressionConverter;
#if macro
import haxe.macro.Expr;
#end

/**
	A SELECT over two rows — C#'s `ISelectQuery<T1, T2>`, which Haxe cannot spell that way since it
	has no overloading on the number of type parameters.

	A lambda here takes both rows, in the order they were joined: `(a, b) -> a.id == b.deliveryId`.
	Joining again, to reach three rows, is still to come.
**/
@:forward
abstract ISelectQuery2<T1, T2>(ISelectQueryRuntime2<T1, T2>) from ISelectQueryRuntime2<T1, T2> to ISelectQueryRuntime2<T1, T2> {
	/** `WHERE <predicate>`, over both rows. Called again, it adds another condition with AND. */
	public macro function Where(self:Expr, predicate:Expr):Expr {
		final condition = ExpressionConverter.Convert(predicate, ExpressionConverter.EntitiesOf(self));
		return macro $self.WhereCondition($condition);
	}

	/** `SELECT DISTINCT …`, or with a key, `SELECT DISTINCT ON (key) …`. */
	public macro function Distinct(self:Expr, ?on:Expr):Expr {
		if (ExpressionConverter.Omitted(on)) {
			return macro $self.DistinctRows();
		}
		final key = ExpressionConverter.ConvertKey(on, ExpressionConverter.EntitiesOf(self));
		return macro $self.DistinctOnKey($key);
	}

	/** `ORDER BY key ASC`, optionally `NULLS FIRST|LAST`. */
	public macro function OrderBy(self:Expr, keySelector:Expr, ?nulls:Expr):Expr {
		final key = ExpressionConverter.ConvertKey(keySelector, ExpressionConverter.EntitiesOf(self));
		final ordering = ExpressionConverter.NullsOrDefault(nulls);
		return macro $self.OrderByKey($key, true, $ordering);
	}

	/** `ORDER BY key DESC`. */
	public macro function OrderByDesc(self:Expr, keySelector:Expr, ?nulls:Expr):Expr {
		final key = ExpressionConverter.ConvertKey(keySelector, ExpressionConverter.EntitiesOf(self));
		final ordering = ExpressionConverter.NullsOrDefault(nulls);
		return macro $self.OrderByKey($key, false, $ordering);
	}

	/** Orders ascending by a key expression. */
	public macro function OrderAsc(self:Expr, keySelector:Expr):Expr {
		final key = ExpressionConverter.ConvertKey(keySelector, ExpressionConverter.EntitiesOf(self));
		return macro $self.OrderByKey($key, true, codequery.sqlexpressions.NullsOrdering.Default);
	}

	/** Orders descending by a key expression. */
	public macro function OrderDesc(self:Expr, keySelector:Expr):Expr {
		final key = ExpressionConverter.ConvertKey(keySelector, ExpressionConverter.EntitiesOf(self));
		return macro $self.OrderByKey($key, false, codequery.sqlexpressions.NullsOrdering.Default);
	}
}
