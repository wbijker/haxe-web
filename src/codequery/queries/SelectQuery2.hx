package codequery.queries;

import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.NullsOrdering;
import codequery.sqlexpressions.OrderByExpression;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;
import codequery.sqlexpressions.SqlBinaryOperator;

/** The implementation behind `ISelectQuery2`. */
class SelectQuery2<T1, T2> implements ISelectQueryRuntime2<T1, T2> {
	public final SelectExpression:SelectExpression;

	final context:SourceContext;

	public function new(expression:SelectExpression, context:SourceContext) {
		this.SelectExpression = expression;
		this.context = context;
	}

	public function ToExpression():SelectExpression {
		return SelectExpression;
	}

	public function WhereCondition(condition:ISqlExpression):ISelectQuery2<T1, T2> {
		return Fork(expression -> expression.Where = expression.Where == null
			? condition
			: new BinarySqlExpression(expression.Where, SqlBinaryOperator.And, condition));
	}

	public function DistinctRows():ISelectQuery2<T1, T2> {
		return Fork(expression -> {
			if (expression.DistinctOn.length > 0) {
				throw "A query is DISTINCT or DISTINCT ON, not both";
			}
			expression.IsDistinct = true;
		});
	}

	public function DistinctOnKey(key:ISqlExpression):ISelectQuery2<T1, T2> {
		return Fork(expression -> {
			if (expression.IsDistinct) {
				throw "A query is DISTINCT or DISTINCT ON, not both";
			}
			expression.DistinctOn.push(key);
		});
	}

	public function OrderByKey(key:ISqlExpression, ascending:Bool, nulls:NullsOrdering):ISelectQuery2<T1, T2> {
		return Fork(expression -> expression.OrderBy.push(new OrderByExpression(key, ascending, nulls)));
	}

	public function Limit(count:Int):ISelectQuery2<T1, T2> {
		return Fork(expression -> expression.Limit = count);
	}

	public function Offset(count:Int):ISelectQuery2<T1, T2> {
		return Fork(expression -> expression.Offset = count);
	}

	public function WithTies():ISelectQuery2<T1, T2> {
		return Fork(expression -> expression.WithTies = true);
	}

	public function Percent():ISelectQuery2<T1, T2> {
		return Fork(expression -> expression.Percent = true);
	}

	public function CountExpression():SelectExpression {
		return RowCount.Counting(SelectExpression, context);
	}

	public function Count():Int {
		return RowCount.Unavailable();
	}

	/** A clause answers with a query of its own; the one it was asked of is unchanged. */
	function Fork(addClause:SelectExpression->Void):ISelectQuery2<T1, T2> {
		final expression = SelectExpression.Fork();
		addClause(expression);
		return new SelectQuery2<T1, T2>(expression, context.Fork());
	}
}
