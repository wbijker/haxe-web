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
	// The rest of C#'s `SqlType`, which the schema needs to name a column by.
	SqlSmallInt;
	SqlReal;
	SqlChar;
	SqlBinary;
	SqlDateTime;
	SqlDateTimeOffset;
	SqlTime;
	SqlGuid;
	SqlJson;
}
