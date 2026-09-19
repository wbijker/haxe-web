package codequery.sqlexpressions;

/** One end of a window frame. */
enum WindowBound {
	UnboundedPreceding;
	Preceding(rows:Int);
	CurrentRow;
	Following(rows:Int);
	UnboundedFollowing;
}
