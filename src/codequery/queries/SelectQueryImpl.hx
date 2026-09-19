package codequery.queries;

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
		return Fork(expression -> {
			expression.GroupBy.push(key);
			if (mode != None) {
				expression.Grouping = mode;
			}
		});
	}

	/** What `GroupByGroupingSets` compiles down to. */
	public function GroupBySet(keys:Array<ISqlExpression>):SelectQueryImpl {
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
		return Fork(expression -> expression.Unions.push(new UnionSqlExpression(type, other.ToExpression())));
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

	public function SelectProjection(selection:ISqlExpression):SelectQueryImpl {
		return Fork(expression -> expression.Selection = selection);
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
