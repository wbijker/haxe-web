package codequery.sqlexpressions;

/**
	`s.contains(term)`, `s.startsWith(term)`, `s.endsWith(term)` — a LIKE whose wildcards are the
	translator's to add.

	The pattern is carried as it was given, whole: a term written into the lambda is a literal the
	wildcards can be written into, and a term from a variable or another column is not, so the
	wildcards are concatenated around it instead. Which of the two it is only matters when the SQL
	is written, so the expression says only the column, the operation and the term.
**/
class StringOperationExpression implements ISqlExpression {
	public final Type:StringOperationType;
	public final Operand:ISqlExpression;
	public final Pattern:ISqlExpression;

	public function new(type:StringOperationType, operand:ISqlExpression, pattern:ISqlExpression) {
		this.Type = type;
		this.Operand = operand;
		this.Pattern = pattern;
	}
}
