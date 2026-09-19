package codequery.sqlexpressions;

/**
	SQL written out, for what nothing else here can say.

	The escape hatch, and the one expression nothing checks: what is in it is sent as it stands, so
	a value belongs in a parameter beside it rather than written into the text.
**/
class RawSqlExpression implements ISqlExpression {
	public final Sql:String;

	public function new(sql:String) {
		this.Sql = sql;
	}
}
