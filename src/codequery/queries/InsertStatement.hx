package codequery.queries;

import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.InsertExpression;
import codequery.sqlexpressions.SourceContext;

/** Builds the INSERT that `DbTable.Insert` compiles down to. */
class InsertStatement {
	/** One row, its columns and values already paired up by the macro that read the entity. */
	public static function Of(table:IQueryTable, columns:Array<String>, values:Array<ISqlExpression>):InsertExpression {
		final context = new SourceContext();
		final source = context.AddTableSource(table.Table);
		final statement = new InsertExpression(source);

		for (column in columns) {
			statement.Columns.push(new ColumnSqlExpression(source, column));
		}
		statement.Values.push(values);
		return statement;
	}
}
