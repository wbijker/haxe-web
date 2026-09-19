package codequery.queries;

import codequery.sqlexpressions.ExpressionConverter;
#if macro
import haxe.macro.Expr;
#end

/**
	The clauses of `ISelectQuery`, for every arity at once.

	C# declares these on each of `ISelectQuery<T1>` … `ISelectQuery<T1..T8>`, eight times over. Here
	they are macros, and a macro cannot be declared on an interface nor generated onto a type — so
	repeating them per arity would mean writing them eight times by hand. As static extensions they
	are written once: each reads the rows it is over from the static type of the query it was called
	on, and answers with the arity that leaves.

	The `ISelectQueryN` types carry `@:using(SelectQueryExtensions)`, so these are in scope wherever
	a query is, without a call site having to write `using`.
**/
class SelectQueryExtensions {
	/** `WHERE <predicate>`. Called again, it adds another condition with AND. */
	public static macro function Where(self:Expr, predicate:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final condition = ExpressionConverter.Convert(predicate, rows);
		return ExpressionConverter.Answering(macro ${Impl(self)}.WhereCondition($condition), rows);
	}

	/**
		`SELECT DISTINCT …`, or with a key, `SELECT DISTINCT ON (key) …` — one row per distinct key,
		the first in the query's own ordering, so `OrderBy` decides which one that is. Called again
		with a key it adds another, making one composite key.
	**/
	public static macro function Distinct(self:Expr, ?on:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		if (ExpressionConverter.Omitted(on)) {
			return ExpressionConverter.Answering(macro ${Impl(self)}.DistinctRows(), rows);
		}
		final key = ExpressionConverter.ConvertKey(on, rows);
		return ExpressionConverter.Answering(macro ${Impl(self)}.DistinctOnKey($key), rows);
	}

	/** `ORDER BY key ASC`, optionally `NULLS FIRST|LAST`. Called again, it adds another term. */
	public static macro function OrderBy(self:Expr, keySelector:Expr, ?nulls:Expr):Expr {
		return Ordered(self, keySelector, nulls, true);
	}

	/** `ORDER BY key DESC` — the direction is the method, not an argument to it. */
	public static macro function OrderByDesc(self:Expr, keySelector:Expr, ?nulls:Expr):Expr {
		return Ordered(self, keySelector, nulls, false);
	}

	/** Orders ascending by a key expression. */
	public static macro function OrderAsc(self:Expr, keySelector:Expr):Expr {
		return Ordered(self, keySelector, null, true);
	}

	/** Orders descending by a key expression. */
	public static macro function OrderDesc(self:Expr, keySelector:Expr):Expr {
		return Ordered(self, keySelector, null, false);
	}

	/** At most `count` rows. */
	public static macro function Limit(self:Expr, count:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		return ExpressionConverter.Answering(macro ${Impl(self)}.LimitRows($count), rows);
	}

	/** Skips `count` rows. */
	public static macro function Offset(self:Expr, count:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		return ExpressionConverter.Answering(macro ${Impl(self)}.OffsetRows($count), rows);
	}

	/** Keeps the rows tying with the last one the limit allows. */
	public static macro function WithTies(self:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		return ExpressionConverter.Answering(macro ${Impl(self)}.KeepTies(), rows);
	}

	/** Reads the limit as a percentage of the rows rather than a count. */
	public static macro function Percent(self:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		return ExpressionConverter.Answering(macro ${Impl(self)}.AsPercent(), rows);
	}

	/**
		`INNER JOIN <source> ON <on>`. The source is a table or another query, and the condition is
		written over every row the query now has: `(a, b, c) -> …` after two joins.
	**/
	public static macro function InnerJoin(self:Expr, source:Expr, on:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Inner");
	}

	/** `LEFT JOIN <source> ON <on>`. */
	public static macro function LeftJoin(self:Expr, source:Expr, on:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Left");
	}

	/** `RIGHT JOIN <source> ON <on>`. */
	public static macro function RightJoin(self:Expr, source:Expr, on:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Right");
	}

	/** `FULL OUTER JOIN <source> ON <on>`. */
	public static macro function OuterJoin(self:Expr, source:Expr, on:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Outer");
	}

	/** `CROSS JOIN <source>` — every row against every row, so there is no condition. */
	public static macro function CrossJoin(self:Expr, source:Expr):Expr {
		return ExpressionConverter.Join(self, source, null, "Cross");
	}

	#if macro
	static function Ordered(self:Expr, keySelector:Expr, nulls:Null<Expr>, ascending:Bool):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final key = ExpressionConverter.ConvertKey(keySelector, rows);

		// An ordering the call site did not ask for is left off rather than passed as its default.
		final ordered = ExpressionConverter.Omitted(nulls)
			? macro ${Impl(self)}.OrderByKey($key, $v{ascending})
			: macro ${Impl(self)}.OrderByKey($key, $v{ascending}, $nulls);
		return ExpressionConverter.Answering(ordered, rows);
	}

	/** The statement underneath, which is where a clause is actually added. */
	static function Impl(self:Expr):Expr {
		return macro(cast $self : codequery.queries.SelectQueryImpl);
	}
	#end
}
