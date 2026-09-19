package codequery.migrations;

/** Provider-agnostic column types, as `DatabaseColumnType` in C#. */
enum DatabaseColumnType {
	Unknown;
	Boolean;
	TinyInt;
	SmallInt;
	Int;
	BigInt;
	Float;
	Double;
	Decimal;
	Char;
	VarChar;
	Text;
	NChar;
	NVarChar;
	NText;
	Binary;
	VarBinary;
	Blob;
	Date;
	Time;
	DateTime;
	DateTimeOffset;
	Timestamp;
	Guid;
	Json;
	Xml;
	Object;
	Extension;
}
