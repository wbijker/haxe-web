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
}
