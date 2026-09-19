package codequery.queries;

import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.ISqlSource;
import codequery.sqlexpressions.JoinSqlExpression;
import codequery.sqlexpressions.JoinType;
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
		return Fork(expression -> expression.Where = expression.Where == null
			? condition
			: new BinarySqlExpression(expression.Where, SqlBinaryOperator.And, condition));
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
