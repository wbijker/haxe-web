package codequery.migrations;

import codequery.sqlexpressions.SqlType;

/** Provider-agnostic column types — what a snapshot records, as the C# `DatabaseColumnType`. */
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

/** Between a column type and the SQL type a statement carries. */
class DatabaseColumnTypes {
	/** The core SQL type a column type stands for. */
	public static function ToSqlType(type:DatabaseColumnType, ?maxLength:Int, ?precision:Int, ?scale:Int):SqlType {
		return switch type {
			case Boolean: SqlBool;
			case TinyInt | SmallInt: SqlSmallInt;
			case Int: SqlInt;
			case BigInt: SqlBigInt;
			case Float | Double: SqlFloat;
			case Decimal: SqlDecimal(precision == null ? 0 : precision, scale == null ? 0 : scale);
			case Char | NChar: SqlChar(maxLength == null ? 0 : maxLength);
			case VarChar | NVarChar: SqlVarChar(maxLength == null ? 0 : maxLength);
			case Text | NText | Xml: SqlText;
			case Binary | VarBinary | Blob: SqlBinary;
			case Date: SqlDate;
			case Time: SqlTime;
			case DateTime | DateTimeOffset | Timestamp: SqlTimestamp;
			case Guid: SqlGuid;
			case Json: SqlJson;
			case Object | Extension | Unknown: SqlUnknown;
		}
	}

	/** The column type a SQL type is recorded as, and the length or precision it carries. */
	public static function OfSqlType(type:SqlType):{type:DatabaseColumnType, maxLength:Null<Int>, precision:Null<Int>, scale:Null<Int>} {
		return switch type {
			case SqlInt: {type: Int, maxLength: null, precision: null, scale: null};
			case SqlBigInt: {type: BigInt, maxLength: null, precision: null, scale: null};
			case SqlSmallInt: {type: SmallInt, maxLength: null, precision: null, scale: null};
			case SqlFloat | SqlReal: {type: Double, maxLength: null, precision: null, scale: null};
			case SqlDecimal(precision, scale):
				{type: Decimal, maxLength: null, precision: precision <= 0 ? null : precision, scale: precision <= 0 ? null : scale};
			case SqlBool: {type: Boolean, maxLength: null, precision: null, scale: null};
			case SqlText: {type: Text, maxLength: null, precision: null, scale: null};
			case SqlVarChar(length): {type: VarChar, maxLength: length <= 0 ? null : length, precision: null, scale: null};
			case SqlChar(length): {type: Char, maxLength: length <= 0 ? null : length, precision: null, scale: null};
			case SqlDate: {type: Date, maxLength: null, precision: null, scale: null};
			case SqlTimestamp: {type: DateTime, maxLength: null, precision: null, scale: null};
			case SqlGuid: {type: Guid, maxLength: null, precision: null, scale: null};
			case SqlJson: {type: Json, maxLength: null, precision: null, scale: null};
			case SqlBinary: {type: Binary, maxLength: null, precision: null, scale: null};
			case SqlNamed(_): {type: Unknown, maxLength: null, precision: null, scale: null};
			case SqlTime: {type: Time, maxLength: null, precision: null, scale: null};
			case SqlUnknown: {type: Unknown, maxLength: null, precision: null, scale: null};
		}
	}

	/** The type by the name the snapshot writes it as; unknown names are `Unknown`. */
	public static function Parse(name:String):DatabaseColumnType {
		if (name == null) {
			return Unknown;
		}
		final lowered = name.toLowerCase();
		for (type in DatabaseColumnType.createAll()) {
			if (Std.string(type).toLowerCase() == lowered) {
				return type;
			}
		}
		// The spellings this port's earlier snapshots used.
		return switch lowered {
			case "bool": Boolean;
			case "timestamp": DateTime;
			case _: Unknown;
		}
	}
}
