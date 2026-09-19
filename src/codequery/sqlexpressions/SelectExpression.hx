package codequery.sqlexpressions;

/**
	A SELECT statement as data. Only what step one needs is here — the source and the WHERE;
	joins, projection, ordering, grouping and the rest follow the same shape.
**/
class SelectExpression {
	public final Source:ISqlSource;
	public var Where:Null<ISqlExpression>;

	public function new(source:ISqlSource) {
		this.Source = source;
	}

	/** A copy, so a clause answers with a statement of its own and leaves this one alone. */
	public function Fork():SelectExpression {
		final copy = new SelectExpression(Source);
		copy.Where = Where;
		return copy;
	}
}
