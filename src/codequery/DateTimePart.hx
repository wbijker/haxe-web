package codequery;

/**
	A unit of a date, for the operations that take one — truncating to it, counting in it, reading
	it off.
**/
enum DateTimePart {
	Year;
	Quarter;
	Month;

	/** The week as the dialect counts it. */
	Week;

	/** The ISO-8601 week: weeks start on Monday and week 1 holds the first Thursday. */
	IsoWeek;

	Day;
	Hour;
	Minute;
	Second;
}

/** What a date operation does. Which parts each supports is the dialect's business. */
enum DateOperation {
	/** Everything below the part is dropped: the start of that year, month, day, hour… */
	Truncate;

	/** Whole parts from one date to another. */
	Difference;

	/** The part read off the date, as a number. */
	Part;

	/** The last moment of the date's month. */
	EndOfMonth;

	/** Seconds since 1970-01-01 UTC. */
	EpochSeconds;
}
