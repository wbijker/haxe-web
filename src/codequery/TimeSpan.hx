package codequery;

/** A span of time, in seconds — C#'s `TimeSpan` — so a column declared as one is a `TIME`. */
abstract TimeSpan(Float) from Float from Int to Float {
	public inline function new(seconds:Float) {
		this = seconds;
	}

	public inline function toSeconds():Float {
		return this;
	}
}
