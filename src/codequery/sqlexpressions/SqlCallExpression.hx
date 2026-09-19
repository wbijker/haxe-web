package codequery.sqlexpressions;

/**
	A call to a function this library does not name — `word_similarity(a, b)` from pg_trgm, an
	extension's own, one of your own.

	The name is a string because there is nothing else it could be; everything around it is not. The
	arguments are expressions, so they are still columns and values the compiler checked, and the
	name itself has to be an identifier — a function being named, not a fragment of SQL being pasted
	in. That is the difference between an escape hatch and a hole: `Sql.call("f(1); DROP TABLE x; --")`
	is refused rather than rendered.

	A function call like any other to the translator, which renders it as `name(args)`.
**/
class SqlCallExpression extends SqlFunctionExpression {
	/**
		A function name, optionally schema-qualified. Deliberately narrow: anything a real function
		name does not contain is something a caller should not be able to write here.
	**/
	static final Identifier = ~/^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)?$/;

	public function new(name:String, arguments:Array<ISqlExpression>) {
		if (name == null || !Identifier.match(name)) {
			throw '\'$name\' is not a function name. This names a function to call — word_similarity, '
				+ 'my_schema.my_function — and nothing else: it is not a way to write SQL by hand.';
		}
		super(name, arguments == null ? [] : arguments);
	}
}
