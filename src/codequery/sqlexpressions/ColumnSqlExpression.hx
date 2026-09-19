package codequery.sqlexpressions;

/** A column of one of the statement's sources. */
class ColumnSqlExpression implements ISqlExpression {
	public final Source:ISqlSource;
	public final ColumnName:String;

	public function new(source:ISqlSource, columnName:String) {
		this.Source = source;
		this.ColumnName = columnName;
	}
}
