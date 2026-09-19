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
		`SELECT <projection>` — what the query answers with, and with it the row type it carries:
		`a -> {store: a.fromStoreId, note: a.noteNo}`.
	**/
	public static macro function Select(self:Expr, projection:Expr):Expr {
		return Projected(self, projection);
	}

	/**
		`SELECT <projection>`, narrowing a query over several rows to one shape — most often a row
		of its own, `(a, b) -> b`.
	**/
	public static macro function Reduce(self:Expr, reduce:Expr):Expr {
		return ExpressionConverter.Reduced(self, reduce);
	}

	/**
		`PIVOT`, portably: one conditional aggregate per pivot value beside the group-by columns —
		`.Pivot(RegionPivot, s -> s.quarter, s -> s.amount, Sum, [{key: "Q1", column: "Q1"}], s -> {region: s.region})`.
		The first argument names the row type the pivot answers with, as C#'s `<TValue, TResult>` does.
	**/
	public static macro function Pivot(self:Expr, result:Expr, forColumn:Expr, value:Expr, aggregate:Expr, pivots:Expr,
			?groupBy:Expr):Expr {
		return ExpressionConverter.Pivot(self, result, forColumn, value, aggregate, pivots, groupBy);
	}

	/**
		`SELECT <aggregates>` — `a -> {rows: a.count(), biggest: a.max(r -> r.quantity)}`, where `a`
		stands for the aggregates of the query's rows. A window the query has defined arrives as a
		further parameter, and an aggregate reads over it with `.over(w)`.
	**/
	public static macro function SelectAggregation(self:Expr, projection:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		// The query is held once, so a window the projection names is the one on the statement
		// being projected rather than one built again by evaluating the chain a second time.
		final aggregated = ExpressionConverter.ConvertAggregation(projection, rows, macro __query);
		final selection = aggregated.selection;
		return ExpressionConverter.Answering(macro {
			final __query = ${Impl(self)};
			__query.SelectProjection($selection);
		}, [aggregated.row]);
	}

	/** `UNION` — the rows of both, with duplicates dropped. */
	public static macro function Union(self:Expr, other:Expr):Expr {
		return ExpressionConverter.SetOperation(self, other, "Union");
	}

	/** `UNION ALL` — the rows of both, duplicates kept. */
	public static macro function UnionAll(self:Expr, other:Expr):Expr {
		return ExpressionConverter.SetOperation(self, other, "UnionAll");
	}

	/** `INTERSECT` — the rows in both. */
	public static macro function Intersect(self:Expr, other:Expr):Expr {
		return ExpressionConverter.SetOperation(self, other, "Intersect");
	}

	/** `EXCEPT` — the rows of this one that are not in the other. */
	public static macro function Except(self:Expr, other:Expr):Expr {
		return ExpressionConverter.SetOperation(self, other, "Except");
	}

	/** `GROUP BY ROLLUP (…)` — the groups, and the totals down to the grand total. */
	public static macro function GroupByRollup(self:Expr, keySelector:Expr):Expr {
		return Grouped(self, keySelector, "Rollup");
	}

	/** `GROUP BY CUBE (…)` — the groups, and every combination of them. */
	public static macro function GroupByCube(self:Expr, keySelector:Expr):Expr {
		return Grouped(self, keySelector, "Cube");
	}

	/**
		`GROUP BY GROUPING SETS ((a), (a, b), ())` — the groupings named one by one:
		`.GroupByGroupingSets(r -> r.unitId, r -> r.guestId)`, each lambda one set.
	**/
	public static macro function GroupByGroupingSets(self:Expr, sets:Array<Expr>):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		var query = Impl(self);
		for (set in sets) {
			final keys = ExpressionConverter.ConvertKeySet(set, rows);
			query = macro $query.GroupBySet($keys);
		}
		return ExpressionConverter.Answering(query, rows);
	}

	/** `WITH <name> AS (<query>)` — a query named in front of this one, which can select from it. */
	public static macro function With(self:Expr, name:Expr, other:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final inner = macro(cast $other : codequery.queries.SelectQueryImpl);
		return ExpressionConverter.Answering(macro ${Impl(self)}.WithQuery($name, $inner), rows);
	}

	/** `WITH RECURSIVE <name> AS (<query>)`. */
	public static macro function WithRecursive(self:Expr, name:Expr, other:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final inner = macro(cast $other : codequery.queries.SelectQueryImpl);
		return ExpressionConverter.Answering(macro ${Impl(self)}.WithQuery($name, $inner, true), rows);
	}

	/** `FOR UPDATE` — the rows read are locked against anyone else changing them. */
	public static macro function ForUpdate(self:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		return ExpressionConverter.Answering(
			macro ${Impl(self)}.Locking(codequery.sqlexpressions.RowLockMode.Update), rows);
	}

	/** `FOR SHARE` — the rows read may be read by others but not changed. */
	public static macro function ForShare(self:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		return ExpressionConverter.Answering(
			macro ${Impl(self)}.Locking(codequery.sqlexpressions.RowLockMode.Share), rows);
	}

	/** `SKIP LOCKED` — rows someone else holds are passed over rather than waited for. */
	public static macro function SkipLocked(self:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		return ExpressionConverter.Answering(
			macro ${Impl(self)}.Locking(codequery.sqlexpressions.RowLockMode.Update, true), rows);
	}

	/** `NOWAIT` — a row someone else holds is an error rather than a wait. */
	public static macro function NoWait(self:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		return ExpressionConverter.Answering(
			macro ${Impl(self)}.Locking(codequery.sqlexpressions.RowLockMode.Update, false, true), rows);
	}

	/** `GROUP BY key`. Called again, it adds another term. */
	public static macro function GroupBy(self:Expr, keySelector:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final key = ExpressionConverter.ConvertKey(keySelector, rows);
		return ExpressionConverter.Answering(macro ${Impl(self)}.GroupByKey($key), rows);
	}

	/** `HAVING <predicate>` — the condition on the groups, as `Where` is the condition on the rows. */
	public static macro function Having(self:Expr, predicate:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final condition = ExpressionConverter.Convert(predicate, rows);
		return ExpressionConverter.Answering(macro ${Impl(self)}.HavingCondition($condition), rows);
	}

	/**
		`WINDOW w AS (…)` — defines a window the query's aggregates can name:

		```haxe
		.Window(w -> w.PartitionBy(a -> a.deliveryId).OrderBy(a -> a.id))
		.SelectAggregation((a, w) -> {running: a.sum(r -> r.quantity).over(w)})
		```

		It arrives as an extra row, which is how the projection after it names the window. Without a
		`name` the first window is `w`.
	**/
	public static macro function Window(self:Expr, spec:Expr, ?name:Expr):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final window = ExpressionConverter.ConvertWindow(spec, rows);
		final partitionBy = window.partitionBy;
		final orderBy = window.orderBy;
		final frame = window.frame;

		final defined = ExpressionConverter.Omitted(name)
			? macro ${Impl(self)}.AddWindow($partitionBy, $orderBy, null, $frame)
			: macro ${Impl(self)}.AddWindow($partitionBy, $orderBy, $name, $frame);
		return ExpressionConverter.Answering(defined, rows.concat([ExpressionConverter.WindowRow()]));
	}

	/**
		`WHERE EXISTS (SELECT * FROM <table> WHERE <correlation>)`. The correlation is written over
		the query's rows and the table's, e.g. `(d, l) -> l.deliveryId == d.id`.
	**/
	public static macro function WhereExists(self:Expr, table:Expr, correlation:Expr):Expr {
		return Existing(self, table, correlation, false);
	}

	/** `WHERE NOT EXISTS (…)`. */
	public static macro function WhereNotExists(self:Expr, table:Expr, correlation:Expr):Expr {
		return Existing(self, table, correlation, true);
	}

	/**
		`INNER JOIN <source> ON <on>`. The source is a table or another query, and the condition is
		written over every row the query now has: `(a, b, c) -> …` after two joins.
	**/
	public static macro function InnerJoin(self:Expr, source:Expr, on:Expr, ?reduce:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Inner", reduce);
	}

	/** `LEFT JOIN <source> ON <on>`. */
	public static macro function LeftJoin(self:Expr, source:Expr, on:Expr, ?reduce:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Left", reduce);
	}

	/** `RIGHT JOIN <source> ON <on>`. */
	public static macro function RightJoin(self:Expr, source:Expr, on:Expr, ?reduce:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Right", reduce);
	}

	/** `FULL OUTER JOIN <source> ON <on>`. */
	public static macro function OuterJoin(self:Expr, source:Expr, on:Expr, ?reduce:Expr):Expr {
		return ExpressionConverter.Join(self, source, on, "Outer", reduce);
	}

	/**
		`CROSS JOIN LATERAL (<query>)` — a query written against the row it is joined to:
		`.InnerJoinLateral(b -> db.Lines.From().Where(l -> l.deliveryId == b.id))`.

		There is no condition, because the correlation is inside the query itself.
	**/
	public static macro function InnerJoinLateral(self:Expr, lateral:Expr):Expr {
		return ExpressionConverter.Lateral(self, lateral, "CrossLateral");
	}

	/** `LEFT JOIN LATERAL (<query>) ON TRUE` — the outer row is kept even where the query is empty. */
	public static macro function LeftJoinLateral(self:Expr, lateral:Expr):Expr {
		return ExpressionConverter.Lateral(self, lateral, "LeftLateral");
	}

	/** `CROSS JOIN <source>` — every row against every row, so there is no condition. */
	public static macro function CrossJoin(self:Expr, source:Expr):Expr {
		return ExpressionConverter.Join(self, source, null, "Cross");
	}

	/**
		`DELETE FROM <target> USING (<this query>) WHERE <on>` — the rows this query finds are what
		is deleted from the named table. C#'s `Delete<TTarget>(on)`; the condition names the target's
		row first and this query's second.
	**/
	public static macro function Delete(self:Expr, target:Expr, condition:Expr):Expr {
		return codequery.queries.MutationFromQuery.Delete(self, target, condition);
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

	static function Grouped(self:Expr, keySelector:Expr, mode:String):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		final key = ExpressionConverter.ConvertKey(keySelector, rows);
		final grouping = macro $p{["codequery", "sqlexpressions", "GroupingMode", mode]};
		return ExpressionConverter.Answering(macro ${Impl(self)}.GroupByKey($key, $grouping), rows);
	}

	static function Existing(self:Expr, table:Expr, correlation:Expr, negate:Bool):Expr {
		final rows = ExpressionConverter.EntitiesOf(self);
		// The correlation names the table's rows after the query's own, so the subquery's source is
		// one past them.
		final condition = ExpressionConverter.Convert(correlation, rows.concat([ExpressionConverter.EntityOf(table)]));
		return ExpressionConverter.Answering(macro ${Impl(self)}.WhereExistsTable($table, $condition, $v{negate}), rows);
	}

	static function Projected(self:Expr, projection:Expr):Expr {
		// The query is held once, so an aggregate reading over a window the query named reaches
		// the window on the statement being projected rather than one built again.
		final projected = ExpressionConverter.ConvertProjection(projection, ExpressionConverter.EntitiesOf(self), macro __query);
		final selection = projected.selection;
		// A projection collapses however many rows the query had to the one shape it answers with.
		return ExpressionConverter.Answering(macro {
			final __query = ${Impl(self)};
			__query.SelectProjection($selection);
		}, [projected.row]);
	}

	/** The statement underneath, which is where a clause is actually added. */
	static function Impl(self:Expr):Expr {
		return macro(cast $self : codequery.queries.SelectQueryImpl);
	}
	#end
}
