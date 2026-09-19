package codequery.sqldrivers;

import codequery.sqlexpressions.ISqlStatement;

/**
	Renders a statement laid out for reading: one clause per line, the selected columns one per
	indented line. C#'s `ToSql(expression, pretty: true)`.

	The layout is applied to the rendered text rather than woven into the renderer: a clause begins
	at a keyword the statement's own text cannot otherwise contain at its top level, so the text
	says where the lines go. A keyword inside a subquery or a string literal is left where it is.
**/
class PrettySqlTranslator extends SqlTranslator {
	public function new() {
		super();
	}

	override public function ToSql(statement:ISqlStatement):String {
		return Pretty(super.ToSql(statement));
	}

	static final Indent = "    ";

	/** The clauses a statement is broken at, longest first so that `GROUP BY` wins over `BY`. */
	static final Clauses = [
		"FULL OUTER JOIN", "CROSS JOIN LATERAL", "LEFT JOIN LATERAL", "INNER JOIN", "LEFT JOIN",
		"RIGHT JOIN", "CROSS JOIN", "GROUP BY", "ORDER BY", "ON CONFLICT", "RETURNING", "SELECT",
		"FROM", "WHERE", "HAVING", "WINDOW", "LIMIT", "OFFSET", "FETCH", "FOR", "UNION",
		"INTERSECT", "EXCEPT", "SET", "VALUES", "USING"
	];

	/** Compact SQL as one clause per line, with the select list one item per line. */
	public static function Pretty(sql:String):String {
		final lines = [];
		var line = "";
		var depth = 0;
		var quoted = false;
		var index = 0;
		while (index < sql.length) {
			final c = sql.charAt(index);
			if (c == "'") {
				quoted = !quoted;
			} else if (!quoted && c == "(") {
				depth++;
			} else if (!quoted && c == ")") {
				depth--;
			} else if (!quoted && depth == 0 && c == " " && line != "") {
				final clause = ClauseAt(sql, index + 1);
				if (clause != null) {
					lines.push(line);
					line = "";
					index++;
					continue;
				}
			}
			line += c;
			index++;
		}
		if (line != "") {
			lines.push(line);
		}
		return lines.map(SelectList).join("\n");
	}

	/** The clause keyword beginning at `at`, or null where the text there is not one. */
	static function ClauseAt(sql:String, at:Int):Null<String> {
		for (clause in Clauses) {
			if (sql.substr(at, clause.length) == clause) {
				final after = sql.charAt(at + clause.length);
				if (after == "" || after == " " || after == "\n") {
					return clause;
				}
			}
		}
		return null;
	}

	/** `SELECT a, b` as `SELECT`, then each item on a line of its own. */
	static function SelectList(line:String):String {
		if (!StringTools.startsWith(line, "SELECT")) {
			return line;
		}
		var head = "SELECT";
		var rest = line.substr(head.length);
		if (StringTools.startsWith(rest, " DISTINCT ON (")) {
			final close = MatchingParen(rest, rest.indexOf("("));
			head += rest.substr(0, close + 1);
			rest = rest.substr(close + 1);
		} else if (StringTools.startsWith(rest, " DISTINCT")) {
			head += " DISTINCT";
			rest = rest.substr(" DISTINCT".length);
		}
		final items = SplitTopLevel(StringTools.trim(rest));
		return head + "\n" + Indent + items.join(",\n" + Indent);
	}

	static function MatchingParen(text:String, open:Int):Int {
		var depth = 0;
		for (index in open...text.length) {
			final c = text.charAt(index);
			if (c == "(") {
				depth++;
			} else if (c == ")") {
				depth--;
				if (depth == 0) {
					return index;
				}
			}
		}
		return text.length - 1;
	}

	/** Split on the commas that are not inside parentheses or a string literal. */
	static function SplitTopLevel(text:String):Array<String> {
		final items = [];
		var item = "";
		var depth = 0;
		var quoted = false;
		for (index in 0...text.length) {
			final c = text.charAt(index);
			if (c == "'") {
				quoted = !quoted;
			} else if (!quoted && c == "(") {
				depth++;
			} else if (!quoted && c == ")") {
				depth--;
			} else if (!quoted && depth == 0 && c == ",") {
				items.push(StringTools.trim(item));
				item = "";
				continue;
			}
			item += c;
		}
		items.push(StringTools.trim(item));
		return items;
	}
}
