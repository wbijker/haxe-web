package codequery.queries;

import codequery.sqlexpressions.AggregateSqlExpression;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;

/** Shapes the statement that counts another statement's rows. */
class RowCount {
	/**
		A query that already counts what it reads can simply select `COUNT(*)` instead of its rows.
		One that does not — one narrowed by DISTINCT, or by a limit — has to be counted from the
		outside, as a subquery, or the count would be of the rows going in rather than coming out.
	**/
	public static function Counting(query:SelectExpression, context:SourceContext):SelectExpression {
		if (CountsWhatItReads(query)) {
			final counted = query.Fork();
			counted.Selection = AggregateSqlExpression.Count();
			// One row comes back, and the columns it was sorted by are no longer selected.
			while (counted.OrderBy.length > 0) {
				counted.OrderBy.pop();
			}
			return counted;
		}

		final wrapping = new SourceContext();
		final counting = new SelectExpression(wrapping.AddQuerySource(query));
		counting.Selection = AggregateSqlExpression.Count();
		return counting;
	}

	static function CountsWhatItReads(query:SelectExpression):Bool {
		return !query.IsDistinct
			&& query.DistinctOn.length == 0
			&& query.Limit == null
			&& query.Offset == null;
	}

	/** Counting runs the query, and no driver can do that yet. */
	public static function Unavailable():Int {
		return NeedsAConnection("Counting", "CountExpression()");
	}

	/**
		Running a statement needs a connection, and a query is built without one.

		A query knows how to be built and rendered and nothing about where it would run — that is
		`DatabaseConfiguration`'s, and a driver's. Asking a bare query to run is asking the wrong
		thing, not asking for something that does not exist.
	**/
	public static function NeedsAConnection(what:String, instead:String):Int {
		throw '$what runs the statement, so it needs a connection to run it against. Hand it to a '
			+ 'DatabaseConfiguration built on a driver that has one — DatabaseConfiguration.Of('
			+ 'new PhpDriver(dsn)).Execute(query.$instead) — or use $instead for the statement '
			+ 'alone.';
	}
}
