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
import codequery.sqlexpressions.ProjectionMember;
import codequery.sqlexpressions.ProjectionSqlExpression;
import codequery.sqlexpressions.QuerySqlSource;
import codequery.sqlexpressions.TableSqlSource;
import codequery.sqlexpressions.NamedWindowSqlSource;
import codequery.sqlexpressions.NullsOrdering;
import codequery.sqlexpressions.OrderByExpression;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;
import codequery.sqlexpressions.SqlBinaryOperator;

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

	public function ToExpression():SelectExpression {
		// A projection makes a query whose source is the query it projected from; nothing added to it
		// yet means the projected query is the statement, as in C#.
		final beneath = Std.downcast(cast SelectExpression.Source, QuerySqlSource);
		if (beneath != null && SelectExpression.IsSimpleWrapper()) {
			return beneath.Query;
		}

		// The same wrapper carrying only DISTINCT, LIMIT or OFFSET: those move inside rather than
		// needing a statement of their own — but only into a query that has none of them already
		// and no UNION, or the two would compose ("the first of the first ten") and folding would
		// quietly mean something else.
		if (beneath != null
			&& SelectExpression.IsEmptyApartFromRowRules()
			&& !beneath.Query.IsDistinct
			&& beneath.Query.DistinctOn.length == 0
			&& beneath.Query.Limit == null
			&& beneath.Query.Offset == null
			&& beneath.Query.Unions.length == 0) {
			final folded = beneath.Query.Fork();
			folded.IsDistinct = SelectExpression.IsDistinct;
			folded.Limit = SelectExpression.Limit;
			folded.Offset = SelectExpression.Offset;
			return folded;
		}

		return SelectExpression;
	}

	public function WhereCondition(condition:ISqlExpression):SelectQueryImpl {
		final condition = context.Resolve(condition);
		return Fork(expression -> AndWhere(expression, condition));
	}

	/** Successive conditions accumulate, as they do in the C# original. */
	static function AndWhere(expression:SelectExpression, condition:ISqlExpression):Void {
		expression.Where = expression.Where == null
			? condition
			: new BinarySqlExpression(expression.Where, SqlBinaryOperator.And, condition);
	}

	public function GroupByKey(key:ISqlExpression, mode:GroupingMode = None):SelectQueryImpl {
		final key = context.Resolve(key);
		return Fork(expression -> {
			expression.GroupBy.push(key);
			if (mode != None) {
				expression.Grouping = mode;
			}
		});
	}

	/** What `GroupByGroupingSets` compiles down to. */
	public function GroupBySet(keys:Array<ISqlExpression>):SelectQueryImpl {
		final keys = keys.map(context.Resolve);
		return Fork(expression -> expression.GroupingSets.push(keys));
	}

	/** What `With` compiles down to: a query named in front of this one. */
	public function WithQuery(name:String, other:SelectQueryImpl, recursive:Bool = false):SelectQueryImpl {
		return Fork(expression -> expression.With.push(
			new CommonTableExpression(name, other.ToExpression(), recursive)));
	}

	/** What the locking clauses compile down to. */
	public function Locking(mode:RowLockMode, skipLocked:Bool = false, noWait:Bool = false):SelectQueryImpl {
		return Fork(expression -> {
			expression.Lock = mode;
			expression.LockSkipLocked = skipLocked;
			expression.LockNoWait = noWait;
		});
	}

	/** What the set operations compile down to. */
	public function UnionWith(type:SetOperationType, other:SelectQueryImpl):SelectQueryImpl {
		// Attached to this query's unwrapped body, and a fresh wrapper answered — so whatever is
		// applied afterwards acts on the combined result, not on the first member, as in C#.
		final body = ToExpression().Fork();
		body.Unions.push(new UnionSqlExpression(type, other.ToExpression()));
		final context = new SourceContext();
		return new SelectQueryImpl(new SelectExpression(context.AddQuerySource(body)), context);
	}

	public function HavingCondition(condition:ISqlExpression):SelectQueryImpl {
		final condition = context.Resolve(condition);
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
		final partitionBy = partitionBy.map(context.Resolve);
		final orderBy = orderBy.map(term -> (cast context.Resolve(term) : OrderByExpression));
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
		subquery.Where = context.Resolve(correlation);

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
		final key = context.Resolve(key);
		return Fork(expression -> {
			if (expression.IsDistinct) {
				throw "A query is DISTINCT or DISTINCT ON, not both";
			}
			expression.DistinctOn.push(key);
		});
	}

	public function OrderByKey(key:ISqlExpression, ascending:Bool, nulls:NullsOrdering = Default):SelectQueryImpl {
		final key = context.Resolve(key);
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
		projected.Selection = context.Resolve(selection);

		final context = new SourceContext();
		return new SelectQueryImpl(new SelectExpression(context.AddQuerySource(projected)), context);
	}

	public function JoinTable(type:JoinType, table:IQueryTable, ?on:ISqlExpression):SelectQueryImpl {
		final context = this.context.Fork();
		return Joined(type, context.AddTableSource(table.Table), context.Resolve(on), context);
	}

	public function JoinQuery(type:JoinType, source:SelectQueryImpl, ?on:ISqlExpression):SelectQueryImpl {
		final context = this.context.Fork();
		// A query that only reads a table is that table, and is joined as one rather than nested —
		// which is how C# renders it.
		final statement = source.ToExpression();
		final table = Std.downcast(cast statement.Source, TableSqlSource);
		if (table != null && statement.IsEmpty()) {
			return Joined(type, context.AddTableSource(table.Table), context.Resolve(on), context);
		}
		return Joined(type, context.AddQuerySource(statement), context.Resolve(on), context);
	}

	/**
		`Reduce` — the projection kept in place rather than made into a query of its own: the
		sources stay where they are and keep their aliases, so the SQL is the same join it was, and
		what follows reads through the row the reduce built. Each member is remembered under its
		name so that `x.u.name` afterwards finds the column `u` stood for.
	**/
	public function ReduceTo(selection:ISqlExpression):SelectQueryImpl {
		final projection = Std.downcast(cast context.Resolve(selection), ProjectionSqlExpression);
		if (projection == null) {
			throw "A reduce builds a row from the sources it joins — reduce: (b, u) -> {b: b, u: u} — "
				+ "and this one is not a row being built.";
		}
		if (projection.Members.length == 0) {
			throw "A reduce projects the joined rows into one: reduce: (b, u) -> {b: b, u: u}.";
		}

		final expression = SelectExpression.Fork();
		expression.Selection = projection;

		final reduced = context.Fork();
		for (member in projection.Members) {
			reduced.RegisterProjected(member.Name, member.Expression);
		}
		reduced.MarkReduced();
		return new SelectQueryImpl(expression, reduced);
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
