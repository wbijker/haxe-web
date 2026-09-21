package codequery;

import codequery.execution.SqlOutcome;
import codequery.execution.SqlQuery;

/**
	Writes every statement to the console as it is sent, and what came back when it did —
	`CodeQuery.ConsoleLogger`:

	```
	→ UPDATE booking AS t0 SET price_zar = t0.price_zar * 1.15 WHERE t0.price_zar > 100
	← 3 rows changed in 2.4 ms
	   src/Main.hx:22 · Main.main()
	```

	The values are written into the statement rather than left as placeholders, so a line can be
	copied out and run as it stands; what went to the database still binds them. The call site is
	where the statement was asked for — a line of its own, so that it reads as a link. A blank line
	closes each statement, so a log of many reads as a list rather than a wall.
**/
class ConsoleLogger implements ISqlLogger {
	/** What the call site is indented by, so that it reads as belonging to the line above it. */
	static inline final Indent = "   ";

	final inlineValues:Bool;

	/** `inlineValues` — the default — writes the bound values into the statement; false keeps the placeholders. */
	public function new(inlineValues:Bool = true) {
		this.inlineValues = inlineValues;
	}

	public function BeforeSend(query:SqlQuery):Void {
		// The arrow marks the statement; the clauses under it line up beneath the SQL rather than
		// beneath the arrow, so a statement reads as one block.
		final sql = inlineValues ? query.Inlined() : query.Sql;
		Sys.println("→ " + StringTools.replace(sql, "\n", "\n  "));
	}

	public function AfterSend(query:SqlQuery, outcome:SqlOutcome):Void {
		final took = '${Math.round(outcome.DurationMs * 10) / 10} ms';
		final rows = outcome.toString();
		Sys.println("← " + (rows == "" ? took : '$rows in $took'));
		if (query.Origin != null) {
			final origin = query.Origin;
			Sys.println('$Indent${origin.File}:${origin.Line}' + (origin.Member == null ? "" : ' · ${origin.Member}()'));
		}
		Sys.println("");
	}
}
