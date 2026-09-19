package codequery;

/** A moment with its zone — C#'s `DateTimeOffset` — so a column declared as one is a `TIMESTAMP WITH TIME ZONE`. */
abstract DateTimeOffset(Date) from Date to Date {
	public inline function new(date:Date) {
		this = date;
	}
}
