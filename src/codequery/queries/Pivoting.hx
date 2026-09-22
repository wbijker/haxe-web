package codequery.queries;

import codequery.sqlexpressions.AggregateSqlExpression;
import codequery.sqlexpressions.AggregateType;
import codequery.sqlexpressions.CaseBranch;
import codequery.sqlexpressions.CaseSqlExpression;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.Expr;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.ProjectionMember;
import codequery.sqlexpressions.ProjectionSqlExpression;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;

/** One pivoted column: the value of the pivot column that selects it, and the name it comes back under. */
class PivotColumn {
	public final Key:ConstSqlExpression;
	public final Column:String;

	public function new(key:ConstSqlExpression, column:String) {
		this.Key = key;
		this.Column = column;
	}
}

/**
	What `Pivot` compiles down to: conditional aggregation, `SUM(CASE WHEN quarter = 'Q1' THEN amount END)`
	per pivot value, beside the group-by columns and grouped by them. No dialect needs a PIVOT
	clause to say it, which is what makes it portable.
**/
class Pivoting {
	public static function Apply(query:SelectQueryImpl, forColumn:ISqlExpression, value:ISqlExpression,
			aggregate:AggregateType, pivots:Array<PivotColumn>, ?groupBy:ISqlExpression, ?shape:codequery.RowShape):SelectQueryImpl {
		final expression = query.SelectExpression.Fork();

		final members:Array<ProjectionMember> = [];
		if (groupBy != null) {
			for (member in AsMembers(groupBy)) {
				members.push(member);
				expression.GroupBy.push(member.Expression);
			}
		}

		for (pivot in pivots) {
			final branch = new CaseBranch(Expr.equal(forColumn, pivot.Key), value);
			final conditional = new AggregateSqlExpression(aggregate, new CaseSqlExpression([branch]));
			members.push(new ProjectionMember(pivot.Column, conditional));
		}
		expression.Selection = new ProjectionSqlExpression(members);

		final context = new SourceContext();
		// The row answered with is the result type the pivot was asked for, where it was named.
		final row = shape != null ? shape : codequery.RowShape.OfSelection(expression.Selection, query.Rows);
		return new SelectQueryImpl(new SelectExpression(context.AddQuerySource(expression)), context, [row]);
	}

	static function AsMembers(expression:ISqlExpression):Array<ProjectionMember> {
		final projection = Std.downcast(cast expression, ProjectionSqlExpression);
		return projection != null ? projection.Members : [new ProjectionMember("Key", expression)];
	}
}
