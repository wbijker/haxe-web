package codequery.queries;

import codequery.sqlexpressions.ExpressionConverter;
#if macro
import haxe.macro.Expr;
#end

/**
	A SELECT under construction — the type every signature of the C# API names, and the type a
	caller holds.

	In C# the clauses that take a lambda take an `Expression<…>`, reified at runtime. Here they are
	macros, so the lambda is converted during compilation. That is why this is an abstract over
	`ISelectQueryRuntime` rather than a plain interface: a macro method cannot be dispatched through
	an interface, but it can hang off an abstract while the interface underneath keeps the runtime
	contract that implementations implement. The two convert to each other implicitly, so a value of
	either can be passed wherever the other is expected.

	Every clause answers with a query of its own; the one it was asked of is unchanged.

	`Limit`, `Offset`, `WithTies`, `Percent` and `ToExpression` take no lambda, so they are ordinary
	methods reached straight through the interface.
**/
@:forward
abstract ISelectQuery<T1>(ISelectQueryRuntime<T1>) from ISelectQueryRuntime<T1> to ISelectQueryRuntime<T1> {
	/** `WHERE <predicate>`, e.g. `a -> a.id == 12`. Called again, it adds another condition with AND. */
	public macro function Where(self:Expr, predicate:Expr):Expr {
		final condition = ExpressionConverter.Convert(predicate, ExpressionConverter.EntityOf(self));
		return macro $self.WhereCondition($condition);
	}

	/**
		`SELECT DISTINCT …`, or with a key, `SELECT DISTINCT ON (key) …` — one row per distinct key,
		the first in the query's own ordering, so `OrderBy` decides which one that is. Called again
		with a key it adds another, making one composite key.
	**/
	public macro function Distinct(self:Expr, ?on:Expr):Expr {
		if (on == null || on.expr.match(EConst(CIdent("null")))) {
			return macro $self.DistinctRows();
		}
		final key = ExpressionConverter.ConvertKey(on, ExpressionConverter.EntityOf(self));
		return macro $self.DistinctOnKey($key);
	}

	/** `ORDER BY key ASC`, optionally `NULLS FIRST|LAST`. Called again, it adds another term. */
	public macro function OrderBy(self:Expr, keySelector:Expr, ?nulls:Expr):Expr {
		final key = ExpressionConverter.ConvertKey(keySelector, ExpressionConverter.EntityOf(self));
		final ordering = ExpressionConverter.NullsOrDefault(nulls);
		return macro $self.OrderByKey($key, true, $ordering);
	}

	/** `ORDER BY key DESC` — the direction is the method, not an argument to it. */
	public macro function OrderByDesc(self:Expr, keySelector:Expr, ?nulls:Expr):Expr {
		final key = ExpressionConverter.ConvertKey(keySelector, ExpressionConverter.EntityOf(self));
		final ordering = ExpressionConverter.NullsOrDefault(nulls);
		return macro $self.OrderByKey($key, false, $ordering);
	}

	/** Orders ascending by a key expression. */
	public macro function OrderAsc(self:Expr, keySelector:Expr):Expr {
		final key = ExpressionConverter.ConvertKey(keySelector, ExpressionConverter.EntityOf(self));
		return macro $self.OrderByKey($key, true, codequery.sqlexpressions.NullsOrdering.Default);
	}

	/** Orders descending by a key expression. */
	public macro function OrderDesc(self:Expr, keySelector:Expr):Expr {
		final key = ExpressionConverter.ConvertKey(keySelector, ExpressionConverter.EntityOf(self));
		return macro $self.OrderByKey($key, false, codequery.sqlexpressions.NullsOrdering.Default);
	}
}
