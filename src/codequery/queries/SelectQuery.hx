package codequery.queries;

import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.ISqlSource;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;
import codequery.sqlexpressions.SqlBinaryOperator;

/** The implementation behind `ISelectQuery`. */
class SelectQuery<T1> implements ISelectQueryRuntime<T1> {
	public final SelectExpression:SelectExpression;

	final context:SourceContext;

	public function new(expression:SelectExpression, context:SourceContext) {
		this.SelectExpression = expression;
		this.context = context;
	}

	/** Starts a query over a table. */
	public static function OverTable<T>(table:QualifiedTableName):SelectQuery<T> {
		final context = new SourceContext();
		return new SelectQuery<T>(new SelectExpression(context.AddTableSource(table)), context);
	}

	public function ToExpression():SelectExpression {
		return SelectExpression;
	}

	public function WhereCondition(condition:Array<ISqlSource>->ISqlExpression):ISelectQuery<T1> {
		// A clause answers with a query of its own; the one it was asked of is unchanged.
		final expression = SelectExpression.Fork();
		final context = this.context.Fork();

		AndWhere(expression, condition(context.Sources));
		return new SelectQuery<T1>(expression, context);
	}

	/** Successive Where calls accumulate, as they do in the C# original. */
	static function AndWhere(expression:SelectExpression, condition:ISqlExpression):Void {
		expression.Where = expression.Where == null
			? condition
			: new BinarySqlExpression(expression.Where, SqlBinaryOperator.And, condition);
	}
}
