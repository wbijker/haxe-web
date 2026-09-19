package codequery.sqlexpressions;

import codequery.DateTimePart;

/**
	A span of time as SQL writes one — `INTERVAL '3 days'`. It is what a `SqlInterval` becomes when
	it reaches a query, and what the difference of two dates is measured against:

	```haxe
	.Where(b -> Date.now() - b.created > SqlInterval.days(3))
	// NOW() - t0.created > INTERVAL '3 days'
	```

	A duration is a type in standard SQL and in PostgreSQL, and is not one in SQL Server or SQLite,
	where the difference of two dates is a number of some unit rather than a span.
**/
class IntervalSqlExpression implements ISqlExpression {
	/** The span itself, in milliseconds. */
	public final Milliseconds:Float;

	public function new(milliseconds:Float) {
		this.Milliseconds = milliseconds;
	}

	/**
		The span as a single whole unit and its count — `{count: 3, part: Day}` for three days — or
		null when it is not a whole number of any one unit (2 days and 4 hours), which then has to be
		written out in full.
	**/
	public var WholeUnits(get, never):Null<{count:Int, part:DateTimePart}>;

	function get_WholeUnits():Null<{count:Int, part:DateTimePart}> {
		if (Milliseconds == 0) {
			return {count: 0, part: Second};
		}
		for (unit in [{size: 86400000.0, part: Day}, {size: 3600000.0, part: Hour}, {size: 60000.0, part: Minute}, {size: 1000.0, part: Second}]) {
			if (Milliseconds % unit.size == 0) {
				return {count: Std.int(Milliseconds / unit.size), part: unit.part};
			}
		}
		return null;
	}
}
