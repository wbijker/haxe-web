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

	Haxe has no overloading on the number of type parameters, so C#'s `ISelectQuery<T1, T2>` is
	`ISelectQuery2<T1, T2>` here; joining is what reaches it.
**/
@:forward
abstract ISelectQuery<T1>(ISelectQueryRuntime<T1>) from ISelectQueryRuntime<T1> to ISelectQueryRuntime<T1> {
	/** `WHERE <predicate>`, e.g. `a -> a.id == 12`. Called again, it adds another condition with AND. */
	public macro function Where(self:Expr, predicate:Expr):Expr {
		final condition = ExpressionConverter.Convert(predicate, ExpressionConverter.EntitiesOf(self));
		return macro $self.WhereCondition($condition);
	}

	/**
		`SELECT DISTINCT …`, or with a key, `SELECT DISTINCT ON (key) …` — one row per distinct key,
		the first in the query's own ordering, so `OrderBy` decides which one that is. Called again
		with a key it adds another, making one composite key.
	**/
	public macro function Distinct(self:Expr, ?on:Expr):Expr {
		if (ExpressionConverter.Omitted(on)) {
			return macro $self.DistinctRows();
		}
		final key = ExpressionConverter.ConvertKey(on, ExpressionConverter.EntitiesOf(self));
		return macro $self.DistinctOnKey($key);
	}

	/** `ORDER BY key ASC`, optionally `NULLS FIRST|LAST`. Called again, it adds another term. */
	public macro function OrderBy(self:Expr, keySelector:Expr, ?nulls:Expr):Expr {
		final key = ExpressionConverter.ConvertKey(keySelector, ExpressionConverter.EntitiesOf(self));
		final ordering = ExpressionConverter.NullsOrDefault(nulls);
		return macro $self.OrderByKey($key, true, $ordering);
	}

	/** `ORDER BY key DESC` — the direction is the method, not an argument to it. */
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

	/**
		`INNER JOIN <source> ON <on>`. The source is a table or another query, and the condition is
		written over both rows: `(a, b) -> a.id == b.deliveryId`.
	**/
	public macro function InnerJoin(self:Expr, source:Expr, on:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Inner");
	}

	/** `LEFT JOIN <source> ON <on>`. */
	public macro function LeftJoin(self:Expr, source:Expr, on:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Left");
	}

	/** `RIGHT JOIN <source> ON <on>`. */
	public macro function RightJoin(self:Expr, source:Expr, on:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Right");
	}

	/** `FULL OUTER JOIN <source> ON <on>`. */
	public macro function OuterJoin(self:Expr, source:Expr, on:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Outer");
	}

	/** `CROSS JOIN <source>` — every row against every row, so there is no condition. */
	public macro function CrossJoin(self:Expr, source:Expr):Expr {
		return ExpressionConverter.Join(self, source, null, "Cross");
	}
}
