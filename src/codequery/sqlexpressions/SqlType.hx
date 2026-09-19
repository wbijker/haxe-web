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
	// The rest of the C# `SqlType`, as far as a schema needs to name them.
	SqlSmallInt;
	SqlChar(length:Int);
	SqlGuid;
	SqlJson;
	SqlBinary;
	SqlTime;
}
