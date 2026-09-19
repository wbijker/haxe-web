package codequery.sqlexpressions;

/**
	`(a, b, c)` — several values compared as one row, which is what `Sql.row` writes and what
	`IS DISTINCT FROM` is worth having a row form for.
**/
class RowSqlExpression implements ISqlExpression {
	public final Values:Array<ISqlExpression>;

	public function new(values:Array<ISqlExpression>) {
		this.Values = values;
	}
}
