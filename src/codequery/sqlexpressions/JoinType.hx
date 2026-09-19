package codequery.sqlexpressions;

/** The joins of the C# enum of the same name. The lateral kinds are not reached yet. */
enum JoinType {
	Inner;
	Left;
	Right;
	Outer;
	Cross;
	CrossLateral;
	LeftLateral;
}
