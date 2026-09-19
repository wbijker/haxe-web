package codequery.sqlexpressions;

/** One `column = value` of a `WHEN MATCHED THEN UPDATE SET`. */
class MergeAssignment {
	public final Column:String;
	public final Value:ISqlExpression;

	public function new(column:String, value:ISqlExpression) {
		this.Column = column;
		this.Value = value;
	}
}
