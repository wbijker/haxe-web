package codequery.sqlexpressions;

/**
	A constant of a native object type (a composite), carried as its ordered field values.

	Rendered as `ROW(f1, f2, …)::TypeName`. The row itself is not something a parameter can carry,
	which is not the same as saying none of it can: the fields are ordinary values, bound as such,
	and the row is built around them in the statement.
**/
class ObjectConstSqlExpression implements ISqlExpression {
	/** The field values, in the object type's declaration order. */
	public final Fields:Array<ISqlExpression>;

	/** The type name the row literal is cast to. */
	public final TypeName:String;

	public function new(fields:Array<ISqlExpression>, typeName:String) {
		this.Fields = fields;
		this.TypeName = typeName;
	}
}
