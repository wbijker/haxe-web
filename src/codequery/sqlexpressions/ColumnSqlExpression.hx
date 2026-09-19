package codequery.sqlexpressions;

/** A column of one of the statement's sources. */
class ColumnSqlExpression implements ISqlExpression {
	public final Source:ISqlSource;
	public final ColumnName:String;

	/** What the column holds, as far as the entity says. */
	public final ColumnType:SqlType;

	public function new(source:ISqlSource, columnName:String, columnType:SqlType = SqlUnknown) {
		this.Source = source;
		this.ColumnName = columnName;
		this.ColumnType = columnType;
	}
}
