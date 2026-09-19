package codequery.queries;

import codequery.execution.DatabaseConfiguration;
import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.ISqlSource;
import codequery.sqlexpressions.JoinSqlExpression;
import codequery.sqlexpressions.CommonTableExpression;
import codequery.sqlexpressions.ExistsSqlExpression;
import codequery.sqlexpressions.RowLockMode;
import codequery.sqlexpressions.GroupingMode;
import codequery.sqlexpressions.SetOperationType;
import codequery.sqlexpressions.UnionSqlExpression;
import codequery.sqlexpressions.JoinType;
import codequery.sqlexpressions.NamedWindowSqlSource;
import codequery.sqlexpressions.NullsOrdering;
import codequery.sqlexpressions.OrderByExpression;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;
import codequery.sqlexpressions.SqlBinaryOperator;
import codequery.sqlexpressions.QuerySqlSource;
import codequery.sqlexpressions.TableSqlSource;

/**
	What every `ISelectQueryN` is, underneath: a statement being built up, and the sources it names.

	C# has a `SelectQuery<T1>`, a `SelectQuery<T1, T2>` and so on up to eight, differing only in the
	types on their signatures — every one of them holds a `SelectExpression` and adds clauses to it,
	which is all this does. The row types live on the `ISelectQueryN` abstracts wrapping this, so
	building the statement needs no generics at all and there is one of this rather than eight.

	Every clause answers with a query of its own; the one it was asked of is unchanged.
**/
class SelectQueryImpl {
	public final SelectExpression:SelectExpression;

	final context:SourceContext;

	public function new(expression:SelectExpression, context:SourceContext) {
		this.SelectExpression = expression;
		this.context = context;
	}

	/** Starts a query over a table, which takes the first alias. */
	public static function OverTable(table:QualifiedTableName):SelectQueryImpl {
		final context = new SourceContext();
		return new SelectQueryImpl(new SelectExpression(context.AddTableSource(table)), context);
	}

	/**
		The statement built so far.

		A projection wraps the statement it projects, so that what comes after it reads the
		projected columns. Asked for as it stands, a wrapper with nothing of its own is the statement
		it wraps; one carrying only the row rules — DISTINCT, LIMIT, OFFSET, a lock, a comment — has
		them moved inside, since they name no columns, so a projection followed by one of them is
		still one SELECT. They move only into a statement that has none of them already and no
		union, or the two would compose and mean something else. A CTE is kept wrapped, so that it is
		hoisted and read by name. This is what C# does.
	**/
	public function ToExpression():SelectExpression {
		final wrapped = Std.downcast(cast SelectExpression.Source, QuerySqlSource);
		if (wrapped == null || wrapped.Query.IsCte) {
			return SelectExpression;
		}
		if (SelectExpression.IsSimpleWrapper()) {
			return wrapped.Query;
		}
		if (SelectExpression.IsEmptyApartFromRowRules() && !wrapped.Query.HasRowRules()
			&& wrapped.Query.Unions.length == 0) {
			// Forked rather than written on: the inner statement belongs to the query this one was
			// projected from, which may still be used on its own.
			final folded = wrapped.Query.Fork();
			folded.IsDistinct = SelectExpression.IsDistinct;
			folded.Limit = SelectExpression.Limit;
			folded.Offset = SelectExpression.Offset;
			folded.WithTies = SelectExpression.WithTies;
			folded.Percent = SelectExpression.Percent;
			folded.Lock = SelectExpression.Lock;
			folded.LockSkipLocked = SelectExpression.LockSkipLocked;
			folded.LockNoWait = SelectExpression.LockNoWait;
			folded.CommentAbove = SelectExpression.CommentAbove;
			folded.CommentBelow = SelectExpression.CommentBelow;
			return folded;
		}
		return SelectExpression;
	}

	public function WhereCondition(condition:ISqlExpression):SelectQueryImpl {
		return Fork(expression -> AndWhere(expression, condition));
	}

	/** Successive conditions accumulate, as they do in the C# original. */
	static function AndWhere(expression:SelectExpression, condition:ISqlExpression):Void {
		expression.Where = expression.Where == null
			? condition
			: new BinarySqlExpression(expression.Where, SqlBinaryOperator.And, condition);
	}

	public function GroupByKey(key:ISqlExpression, mode:GroupingMode = None):SelectQueryImpl {
		return GroupByKeys([key], mode);
	}

	/**
		`GROUP BY` one or more keys — a composite key is several terms, as `ROLLUP (a, b)` takes them.

		Normally on the statement being built. Not when that statement already dedupes —
		`Select(…).Distinct().GroupBy(…)` — because SQL runs its DISTINCT after the grouping rather
		than before it, and "the distinct pairs, counted" would become "count, then dedupe the
		counts". So a deduping statement is put in a derived table and the grouping reads from that,
		which is the order the two were written in. C#'s `GroupingScope`.
	**/
	public function GroupByKeys(keys:Array<ISqlExpression>, mode:GroupingMode = None):SelectQueryImpl {
		return GroupingScope().Fork(expression -> {
			for (key in keys) {
				expression.GroupBy.push(key);
			}
			if (mode != None) {
				expression.Grouping = mode;
			}
		});
	}

	/** The query a grouping is added to: this one, or a fresh one over it where this one dedupes. */
	function GroupingScope():SelectQueryImpl {
		if (!SelectExpression.IsDistinct && SelectExpression.DistinctOn.length == 0) {
			return this;
		}
		final nested = new SourceContext();
		return new SelectQueryImpl(new SelectExpression(nested.AddQuerySource(SelectExpression)), nested);
	}

	/** What `GroupByGroupingSets` compiles down to. */
	public function GroupBySet(keys:Array<ISqlExpression>):SelectQueryImpl {
		return Fork(expression -> {
			expression.GroupingSets.push(keys);
			expression.Grouping = GroupingSets;
		});
	}

	/**
		Marks the statement as a CTE. Not forked, and deliberately: this marks the statement other
		queries already hold, so that one of them hoists it into a WITH clause. A copy would be
		marked and never read.
	**/
	public function MarkCte(?name:String):SelectQueryImpl {
		final body = ToExpression();
		body.IsCte = true;
		body.CteName = name;
		return this;
	}

	/**
		`WITH RECURSIVE name AS (<this> UNION ALL <member>)`. This query is the anchor; the member
		was written against a table called `name`, which the WITH clause defines — so the reference
		is a plain table read and there is no object cycle.
	**/
	public function RecursiveWith(name:String, member:SelectQueryImpl):SelectQueryImpl {
		final anchor = ToExpression().Fork();
		anchor.IsCte = true;
		anchor.CteName = name;
		anchor.IsRecursive = true;
		anchor.Unions.push(new UnionSqlExpression(UnionAll, member.ToExpression()));

		final context = new SourceContext();
		return new SelectQueryImpl(new SelectExpression(context.AddQuerySource(anchor)), context);
	}

	/** `-- above` before the statement and `-- below` after it — `WithComments`. */
	public function Commented(?above:String, ?below:String):SelectQueryImpl {
		return Fork(expression -> {
			expression.CommentAbove = above;
			expression.CommentBelow = below;
		});
	}

	/** What `With` compiles down to: a query named in front of this one. */
	public function WithQuery(name:String, other:SelectQueryImpl, recursive:Bool = false):SelectQueryImpl {
		return Fork(expression -> expression.With.push(
			new CommonTableExpression(name, other.ToExpression(), recursive)));
	}

	/** What the locking clauses compile down to. A second mode changes the lock rather than adding one. */
	public function Locking(mode:RowLockMode, ?skipLocked:Bool, ?noWait:Bool):SelectQueryImpl {
		return Fork(expression -> {
			expression.Lock = mode;
			if (skipLocked != null) {
				expression.LockSkipLocked = skipLocked;
			}
			if (noWait != null) {
				expression.LockNoWait = noWait;
			}
		});
	}

	/**
		`SKIP LOCKED` or `NOWAIT` — one or the other, the last said. Either says something about a
		lock, so a query that has not taken one is told rather than the call quietly doing nothing.
	**/
	public function Waiting(skip:Bool):SelectQueryImpl {
		return Fork(expression -> {
			if (expression.Lock == None) {
				throw NoLock(skip ? "SkipLocked" : "NoWait");
			}
			expression.LockSkipLocked = skip;
			expression.LockNoWait = !skip;
		});
	}

	/**
		`FOR UPDATE OF <table>` — locks only the rows of that table. Without it the lock takes every
		row the query touched, joined tables included. Called again, it names another table.
	**/
	public function LockOf(table:IQueryTable):SelectQueryImpl {
		return Fork(expression -> {
			if (expression.Lock == None) {
				throw NoLock("OfTable");
			}
			final wanted = table.Table.Name;
			var named:Null<ISqlSource> = null;
			for (source in [expression.Source].concat(expression.Joins.map(join -> join.Source))) {
				final read = Std.downcast(cast source, TableSqlSource);
				if (read != null && read.Table.Name == wanted) {
					named = read;
					break;
				}
			}
			if (named == null) {
				throw 'This query does not select from \'$wanted\', so its lock cannot name it. '
					+ 'FOR UPDATE OF names a table the statement reads.';
			}
			if (expression.LockTables.indexOf(named) < 0) {
				expression.LockTables.push(named);
			}
		});
	}

	static function NoLock(called:String):String {
		return '$called says something about a lock, and this query has not taken one. '
			+ 'Take it first: ForUpdate(), ForNoKeyUpdate(), ForShare() or ForKeyShare().';
	}

	/**
		What the set operations compile down to. The member is attached to the statement as it
		stands and a fresh wrapper answered with, so that what is added afterwards — a WHERE, an
		ORDER BY — acts on the combined rows rather than on the first member.
	**/
	public function UnionWith(type:SetOperationType, other:SelectQueryImpl):SelectQueryImpl {
		final body = ToExpression().Fork();
		body.Unions.push(new UnionSqlExpression(type, other.ToExpression()));

		final context = new SourceContext();
		return new SelectQueryImpl(new SelectExpression(context.AddQuerySource(body)), context);
	}

	public function HavingCondition(condition:ISqlExpression):SelectQueryImpl {
		return Fork(expression -> expression.Having = expression.Having == null
			? condition
			: new BinarySqlExpression(expression.Having, SqlBinaryOperator.And, condition));
	}

	/**
		Defines a window on the statement. Unnamed, the first is `w` and the rest follow it — which
		is why naming happens here rather than where the spec was written: only the statement knows
		how many it already has.
	**/
	public function AddWindow(partitionBy:Array<ISqlExpression>, orderBy:Array<OrderByExpression>, ?name:String):SelectQueryImpl {
		return Fork(expression -> {
			final given = name != null ? name : (expression.Windows.length == 0 ? "w" : "w" + expression.Windows.length);
			expression.Windows.push(new NamedWindowSqlSource(given, partitionBy, orderBy));
		});
	}

	/** The window among a statement's sources at `index`, which is how a projection names one. */
	public static function WindowOf(query:SelectQueryImpl, index:Int):NamedWindowSqlSource {
		final source = query.SelectExpression.AllSources()[index];
		final window = Std.downcast(cast source, NamedWindowSqlSource);
		if (window == null) {
			throw 'Row $index of this query is not a window';
		}
		return window;
	}

	/**
		`WHERE EXISTS (SELECT * FROM <table> WHERE <correlation>)`.

		The subquery's source is drawn from this statement's own context, so its alias cannot
		collide with one the outer statement is already using — which is what lets the correlation
		name rows on both sides.
	**/
	public function WhereExistsTable(table:IQueryTable, correlation:ISqlExpression, negate:Bool):SelectQueryImpl {
		final context = this.context.Fork();
		final subquery = new SelectExpression(context.AddTableSource(table.Table));
		subquery.Where = correlation;

		final expression = SelectExpression.Fork();
		AndWhere(expression, new ExistsSqlExpression(subquery, negate));
		return new SelectQueryImpl(expression, context);
	}

	public function DistinctRows():SelectQueryImpl {
		return Fork(expression -> {
			// SQL has one slot for it — SELECT [ ALL | DISTINCT [ ON (…) ] ] — so a query is one or
			// the other, and asking for both is a mistake rather than a choice to resolve.
			if (expression.DistinctOn.length > 0) {
				throw "A query is DISTINCT or DISTINCT ON, not both";
			}
			expression.IsDistinct = true;
		});
	}

	public function DistinctOnKey(key:ISqlExpression):SelectQueryImpl {
		return Fork(expression -> {
			if (expression.IsDistinct) {
				throw "A query is DISTINCT or DISTINCT ON, not both";
			}
			expression.DistinctOn.push(key);
		});
	}

	public function OrderByKey(key:ISqlExpression, ascending:Bool, nulls:NullsOrdering = Default):SelectQueryImpl {
		return Fork(expression -> expression.OrderBy.push(new OrderByExpression(key, ascending, nulls)));
	}

	public function LimitRows(count:Int):SelectQueryImpl {
		return Fork(expression -> expression.Limit = count);
	}

	public function OffsetRows(count:Int):SelectQueryImpl {
		return Fork(expression -> expression.Offset = count);
	}

	public function KeepTies():SelectQueryImpl {
		return Fork(expression -> expression.WithTies = true);
	}

	public function AsPercent():SelectQueryImpl {
		return Fork(expression -> expression.Percent = true);
	}

	/**
		`SELECT <projection>`, and a query of the shape it projects.

		The query it answers with reads the columns this one selects, not the ones this one reads —
		`.Select(b -> {total: b.totalCents}).Where(r -> r.total > 0)` is a condition on `total`,
		which only exists once the projection has happened. So this statement becomes the source of
		a new one rather than being amended, which is what C# does and what makes a projection
		something that can be queried again.
	**/
	public function SelectProjection(selection:ISqlExpression):SelectQueryImpl {
		final projected = SelectExpression.Fork();
		projected.Selection = selection;

		final context = new SourceContext();
		return new SelectQueryImpl(new SelectExpression(context.AddQuerySource(projected)), context);
	}

	public function JoinTable(type:JoinType, table:IQueryTable, ?on:ISqlExpression):SelectQueryImpl {
		final context = this.context.Fork();
		return Joined(type, context.AddTableSource(table.Table), on, context);
	}

	public function JoinQuery(type:JoinType, source:SelectQueryImpl, ?on:ISqlExpression):SelectQueryImpl {
		final context = this.context.Fork();
		return Joined(type, context.AddQuerySource(source.ToExpression()), on, context);
	}

	function Joined(type:JoinType, source:ISqlSource, on:Null<ISqlExpression>, context:SourceContext):SelectQueryImpl {
		final expression = SelectExpression.Fork();
		expression.Joins.push(new JoinSqlExpression(type, source, on));
		return new SelectQueryImpl(expression, context);
	}

	/**
		The statement that counts this one's rows — what `Count` would run.

		Not in the C# API, where counting only ever runs; it is separated out here because rendering
		is all this port can do until a driver can execute.
	**/
	public function CountExpression():SelectExpression {
		// The statement as it stands, wrapper and all, as the C# does: a projection that aggregates
		// returns one row however many it read, and one is what its wrapper counts.
		return RowCount.Counting(SelectExpression, context);
	}

	/** How many rows the query has. Runs the query, so it needs a connection to run it against. */
	public function Count():Int {
		return RowCount.Unavailable();
	}

	function Fork(addClause:SelectExpression->Void):SelectQueryImpl {
		final expression = SelectExpression.Fork();
		addClause(expression);
		return new SelectQueryImpl(expression, context.Fork());
	}
}
