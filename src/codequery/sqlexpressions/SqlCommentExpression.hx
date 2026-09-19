package codequery.sqlexpressions;

/**
	A value with a comment attached — the value, then the comment in block form beside it.

	The block form rather than `--`, because this sits inside a statement: a line comment runs to
	the end of its line and would take the rest of the statement with it. It wraps the value rather
	than replacing it — the comment is something said about the expression, and the expression
	still has to render — so anything reading the tree for what it computes reads through `Value`.
**/
class SqlCommentExpression implements ISqlExpression {
	/** The expression the comment is about. */
	public final Value:ISqlExpression;

	/** The comment itself, with anything that would end it early taken out. */
	public final Text:String;

	public function new(value:ISqlExpression, text:Null<String>) {
		this.Value = value;
		this.Text = Sanitize(text);
	}

	/**
		A comment cannot contain the thing that closes it: the star-slash pair in the text would end
		it early and leave the rest standing in the statement as SQL, so the two are separated. A
		comment of several lines becomes one, since the statement is one line too.
	**/
	static function Sanitize(text:Null<String>):String {
		var cleaned = text == null ? "" : text;
		cleaned = StringTools.replace(cleaned, "*/", "* /");
		cleaned = StringTools.replace(cleaned, "\r\n", " ");
		cleaned = StringTools.replace(cleaned, "\n", " ");
		return StringTools.trim(cleaned);
	}
}
