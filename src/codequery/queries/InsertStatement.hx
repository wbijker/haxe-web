package codequery.queries;

import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.InsertExpression;
import codequery.sqlexpressions.SelectExpression;
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

	/** Several rows, all of the same columns. */
	public static function Many(table:IQueryTable, columns:Array<String>,
			rows:Array<Array<ISqlExpression>>):InsertExpression {
		final statement = Empty(table, columns);
		for (row in rows) {
			statement.Values.push(row);
		}
		return statement;
	}

	/** The rows another statement selects, rather than values. */
	public static function FromQuery(table:IQueryTable, columns:Array<String>,
			source:SelectExpression):InsertExpression {
		final statement = Empty(table, columns);
		statement.FromSelect = source;
		return statement;
	}

	static function Empty(table:IQueryTable, columns:Array<String>):InsertExpression {
		final context = new SourceContext();
		final source = context.AddTableSource(table.Table);
		final statement = new InsertExpression(source);
		for (column in columns) {
			statement.Columns.push(new ColumnSqlExpression(source, column));
		}
		return statement;
	}
}
