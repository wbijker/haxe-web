package codequery.queries;

import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.NullsOrdering;
import codequery.sqlexpressions.OrderByExpression;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;
import codequery.sqlexpressions.SqlBinaryOperator;
import codequery.sqlexpressions.TableSqlSource;

/** The implementation behind `ISelectQuery`. */
class SelectQuery<T1> implements ISelectQueryRuntime<T1> {
	public final SelectExpression:SelectExpression;

	final context:SourceContext;

	public function new(expression:SelectExpression, context:SourceContext) {
		this.SelectExpression = expression;
		this.context = context;
	}

	/** Starts a query over a table. */
	public static function OverSource<T>(source:TableSqlSource):SelectQuery<T> {
		final context = new SourceContext();
		context.Add(source);
		return new SelectQuery<T>(new SelectExpression(source), context);
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
