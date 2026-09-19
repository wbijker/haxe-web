package codequery.sqlexpressions;

/**
	A string tested for a pattern — what `s.contains("x")`, `s.startsWith("x")` and
	`s.endsWith("x")` become. The pattern is kept as it was written; the wildcards are the
	translator's to add, so a pattern held in a variable is concatenated with them rather than
	written into the statement.
**/
class StringOperationExpression implements ISqlExpression {
	public final Operand:ISqlExpression;
	public final OperationType:StringOperationType;
	public final Pattern:ISqlExpression;

	public function new(operand:ISqlExpression, operationType:StringOperationType, pattern:ISqlExpression) {
		this.Operand = operand;
		this.OperationType = operationType;
		this.Pattern = pattern;
	}
}
