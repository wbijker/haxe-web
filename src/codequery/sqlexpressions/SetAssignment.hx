package codequery.sqlexpressions;

/** One `column = value` of an UPDATE's SET. */
class SetAssignment {
	public final Column:ColumnSqlExpression;
	public final Value:ISqlExpression;

	public function new(column:ColumnSqlExpression, value:ISqlExpression) {
		this.Column = column;
		this.Value = value;
	}
}
