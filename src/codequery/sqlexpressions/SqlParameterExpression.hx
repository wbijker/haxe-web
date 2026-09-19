package codequery.sqlexpressions;

/**
	A value sent beside the statement rather than written into it.

	A literal in the SQL has to be escaped correctly every time to be safe, and gives the database a
	different statement for every value it is asked about. A parameter is neither: the text is the
	same whatever the value, and the value never has to be escaped because it never becomes text.
**/
class SqlParameterExpression implements ISqlExpression {
	public final Value:SqlConstValue;

	/** Filled in as the statement renders, since a placeholder is numbered by where it lands. */
	public var Ordinal:Int = 0;

	public function new(value:SqlConstValue) {
		this.Value = value;
	}
}
