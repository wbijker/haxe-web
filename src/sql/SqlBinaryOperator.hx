package sql;

/** The SQL operators `where()` can produce, carrying their SQL text. */
enum abstract SqlBinaryOperator(String) to String {
	var Eq = "=";
	var NotEq = "<>";
	var Gt = ">";
	var Gte = ">=";
	var Lt = "<";
	var Lte = "<=";
	var And = "AND";
	var Or = "OR";

	/** Binding strength, used to decide where parentheses are actually needed. */
	public function precedence():Int {
		return switch (cast this : SqlBinaryOperator) {
			case Or: 1;
			case And: 2;
			case _: 3;
		}
	}
}
