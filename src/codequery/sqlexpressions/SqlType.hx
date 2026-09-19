package codequery.sqlexpressions;

/** The types a column can have, as far as this port needs to name them. */
enum SqlType {
	SqlInt;
	SqlBigInt;
	SqlFloat;
	SqlDecimal(precision:Int, scale:Int);
	SqlBool;
	SqlText;
	SqlVarChar(length:Int);
	SqlDate;
	SqlTimestamp;
	SqlUnknown;

	/** A two-byte integer. */
	SqlSmallInt;

	/** A single-precision float — `REAL`, where `SqlFloat` is the double. */
	SqlReal;

	/**
		A type named by the caller rather than known here — `jsonb`, `tsvector`, a dialect's own —
		so a cast can reach a type this port has never heard of.
	**/
	SqlNamed(name:String);
}
