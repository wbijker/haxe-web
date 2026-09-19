package codequery.queries;

import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.JoinSqlExpression;
import codequery.sqlexpressions.JoinType;
import codequery.sqlexpressions.NullsOrdering;
import codequery.sqlexpressions.OrderByExpression;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;
import codequery.sqlexpressions.ISqlSource;
import codequery.sqlexpressions.SqlBinaryOperator;

/** The implementation behind `ISelectQuery`. */
class SelectQuery<T1> implements ISelectQueryRuntime<T1> {
	public final SelectExpression:SelectExpression;

	final context:SourceContext;

	public function new(expression:SelectExpression, context:SourceContext) {
		this.SelectExpression = expression;
		this.context = context;
	}

	/** Starts a query over a table, which takes the first alias. */
	public static function OverTable<T>(table:QualifiedTableName):SelectQuery<T> {
		final context = new SourceContext();
		return new SelectQuery<T>(new SelectExpression(context.AddTableSource(table)), context);
	}

	public function ToExpression():SelectExpression {
		return SelectExpression;
	}

	public function WhereCondition(condition:ISqlExpression):ISelectQuery<T1> {
		return Fork(expression -> AndWhere(expression, condition));
	}

	public function DistinctRows():ISelectQuery<T1> {
		return Fork(expression -> {
			// SQL has one slot for it — SELECT [ ALL | DISTINCT [ ON (…) ] ] — so a query is one or
			// the other, and asking for both is a mistake rather than a choice to resolve.
			if (expression.DistinctOn.length > 0) {
				throw "A query is DISTINCT or DISTINCT ON, not both";
			}
			expression.IsDistinct = true;
		});
	}

	public function DistinctOnKey(key:ISqlExpression):ISelectQuery<T1> {
		return Fork(expression -> {
			if (expression.IsDistinct) {
				throw "A query is DISTINCT or DISTINCT ON, not both";
			}
			expression.DistinctOn.push(key);
		});
	}

	public function OrderByKey(key:ISqlExpression, ascending:Bool, nulls:NullsOrdering):ISelectQuery<T1> {
		return Fork(expression -> expression.OrderBy.push(new OrderByExpression(key, ascending, nulls)));
	}

	public function Limit(count:Int):ISelectQuery<T1> {
		return Fork(expression -> expression.Limit = count);
	}

	public function Offset(count:Int):ISelectQuery<T1> {
		return Fork(expression -> expression.Offset = count);
	}

	public function WithTies():ISelectQuery<T1> {
		return Fork(expression -> expression.WithTies = true);
	}

	public function Percent():ISelectQuery<T1> {
		return Fork(expression -> expression.Percent = true);
	}

	public function JoinTable<T2>(type:JoinType, table:IQuery<T2>, on:Null<ISqlExpression>):ISelectQuery2<T1, T2> {
		final context = this.context.Fork();
		return Joined(type, context.AddTableSource(table.Table), on, context);
	}

	public function JoinQuery<T2>(type:JoinType, source:ISelectQuery<T2>, on:Null<ISqlExpression>):ISelectQuery2<T1, T2> {
		final context = this.context.Fork();
		return Joined(type, context.AddQuerySource(source.ToExpression()), on, context);
	}

	function Joined<T2>(type:JoinType, source:ISqlSource, on:Null<ISqlExpression>, context:SourceContext):ISelectQuery2<T1, T2> {
		final expression = SelectExpression.Fork();
		expression.Joins.push(new JoinSqlExpression(type, source, on));
		return new SelectQuery2<T1, T2>(expression, context);
	}

	public function CountExpression():SelectExpression {
		return RowCount.Counting(SelectExpression, context);
	}

	public function Count():Int {
		return RowCount.Unavailable();
	}

	/** A clause answers with a query of its own; the one it was asked of is unchanged. */
	function Fork(addClause:SelectExpression->Void):ISelectQuery<T1> {
		final expression = SelectExpression.Fork();
		addClause(expression);
		return new SelectQuery<T1>(expression, context.Fork());
	}

	/** Successive Where calls accumulate, as they do in the C# original. */
	static function AndWhere(expression:SelectExpression, condition:ISqlExpression):Void {
		expression.Where = expression.Where == null
			? condition
			: new BinarySqlExpression(expression.Where, SqlBinaryOperator.And, condition);
	}
}
