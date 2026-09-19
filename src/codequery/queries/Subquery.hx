package codequery.queries;

import codequery.sqlexpressions.AggregateSqlExpression;
import codequery.sqlexpressions.QuerySqlSource;
import codequery.sqlexpressions.SelectExpression;

/**
	A query where a statement stands inside another — `EXISTS (…)`, `x IN (…)`, a scalar `(…)`.

	`Select` answers with a query wrapped around its projection, so that the clauses after it read
	the projected columns. As a subquery that wrapper says nothing: `(SELECT * FROM (SELECT …) AS t)`
	is `(SELECT …)`. It is taken off here, which is also what keeps a correlation counting right —
	a column the subquery reads from the statement around it is one statement out, and the wrapper
	is not a statement anyone wrote.
**/
class Subquery {
	/** The statement a query stands for as a subquery — a copy, so the query itself is left alone. */
	public static function Of(query:SelectQueryImpl):SelectExpression {
		return Unwrapped(query.ToExpression()).Fork();
	}

	/** The same, with `LIMIT 1` — what `FirstOrDefault()` and `FetchFirst()` ask for. */
	public static function Limited(query:SelectQueryImpl, count:Int):SelectExpression {
		final statement = Of(query);
		statement.Limit = count;
		return statement;
	}

	/** The same, counting its rows — what `Count()` inside a lambda asks for. */
	public static function Counting(query:SelectQueryImpl):SelectExpression {
		final statement = Of(query);
		statement.Selection = AggregateSqlExpression.Count();
		// One number comes back, so there is nothing left to order.
		while (statement.OrderBy.length > 0) {
			statement.OrderBy.pop();
		}
		return statement;
	}

	/** The statement with every bare projection wrapper taken off. */
	public static function Unwrapped(statement:SelectExpression):SelectExpression {
		var inner = statement;
		while (IsPlain(inner)) {
			final source = Std.downcast(cast inner.Source, QuerySqlSource);
			if (source == null || !source.Projected) {
				break;
			}
			inner = source.Query;
		}
		return inner;
	}

	/** Whether a statement says nothing beyond its source: `SELECT * FROM <source>`, and that is all. */
	public static function IsPlain(statement:SelectExpression):Bool {
		return statement.Selection == null
			&& statement.Joins.length == 0
			&& statement.Where == null
			&& statement.GroupBy.length == 0
			&& statement.GroupingSets.length == 0
			&& statement.With.length == 0
			&& statement.Having == null
			&& statement.Windows.length == 0
			&& !statement.IsDistinct
			&& statement.DistinctOn.length == 0
			&& statement.OrderBy.length == 0
			&& statement.Unions.length == 0
			&& statement.Limit == null
			&& statement.Offset == null
			&& statement.Lock.match(None);
	}

	/**
		What `.Any()`, `.Sum(…)` and the rest do when called outside a query lambda: nothing, and
		say so. Inside a lambda they are read while compiling and never run; outside one there is no
		row to ask about, which is C#'s `NotSupportedException` here.
	**/
	public static function Outside(operation:String):Dynamic {
		throw '$operation asks a question about the row a query lambda is written over, so it means '
			+ 'something only inside one. Outside a lambda, run the query on a connection instead.';
	}
}
