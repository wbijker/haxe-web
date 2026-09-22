package codequery;

import codequery.sqlexpressions.*;

/**
	Turns what a driver hands back into the values the row type promises.

	PDO answers with strings for most of what MySQL sends, and SQLite with whatever it stored, so a
	fetched row is read column by column through here: the generated `Read` of an entity's columns
	type converts by the field's type, and a projected row by the type its expression can be seen
	to have.
**/
class RowReader {
	public static function AsInt(v:Dynamic):Null<Int> {
		if (v == null) {
			return null;
		}
		if (Std.isOfType(v, Int)) {
			return v;
		}
		if (Std.isOfType(v, Float)) {
			return Std.int(v);
		}
		if (Std.isOfType(v, Bool)) {
			return v ? 1 : 0;
		}
		return Std.parseInt(Std.string(v));
	}

	public static function AsFloat(v:Dynamic):Null<Float> {
		if (v == null) {
			return null;
		}
		if (Std.isOfType(v, Float) || Std.isOfType(v, Int)) {
			return v;
		}
		return Std.parseFloat(Std.string(v));
	}

	public static function AsBool(v:Dynamic):Null<Bool> {
		if (v == null) {
			return null;
		}
		if (Std.isOfType(v, Bool)) {
			return v;
		}
		if (Std.isOfType(v, Int) || Std.isOfType(v, Float)) {
			return v != 0;
		}
		return switch Std.string(v).toLowerCase() {
			case "1" | "t" | "true" | "y" | "yes": true;
			case _: false;
		}
	}

	public static function AsString(v:Dynamic):Null<String> {
		return v == null ? null : Std.string(v);
	}

	/** A date as the driver sends it — `YYYY-MM-DD`, or with a time of day — or one already. */
	public static function AsDate(v:Dynamic):Null<Date> {
		if (v == null) {
			return null;
		}
		if (Std.isOfType(v, Date)) {
			return v;
		}
		if (Std.isOfType(v, Float) || Std.isOfType(v, Int)) {
			return Date.fromTime(v);
		}
		final text = Std.string(v);
		// Fractional seconds and a zone are more than Date.fromString reads.
		final trimmed = ~/\.[0-9]+.*$/.replace(text, "");
		return try Date.fromString(trimmed) catch (_:Dynamic) null;
	}

	/** A value as the type its column is known to have; as it came where the type is not known. */
	public static function As(v:Dynamic, type:SqlType):Dynamic {
		return switch type {
			case SqlInt | SqlBigInt | SqlSmallInt: AsInt(v);
			case SqlFloat | SqlDecimal(_, _) | SqlReal: AsFloat(v);
			case SqlBool: AsBool(v);
			case SqlText | SqlVarChar(_) | SqlChar(_) | SqlGuid: AsString(v);
			case SqlDate | SqlTimestamp: AsDate(v);
			case _: v;
		}
	}

	/**
		The type an expression can be seen to have, as far as reading a value back needs it: a
		column's is declared, a constant's is its value, an arithmetic's is its operands', a
		comparison's is a boolean. `SqlUnknown` where nothing says.
	**/
	public static function TypeOf(e:ISqlExpression):SqlType {
		if (e == null) {
			return SqlUnknown;
		}
		final column = Std.downcast(cast e, ColumnSqlExpression);
		if (column != null) {
			return column.ColumnType;
		}
		final constant = Std.downcast(cast e, ConstSqlExpression);
		if (constant != null) {
			return TypeOfValue(constant.Value);
		}
		final parameter = Std.downcast(cast e, SqlParameterExpression);
		if (parameter != null) {
			return TypeOfValue(parameter.Value);
		}
		final binary = Std.downcast(cast e, BinarySqlExpression);
		if (binary != null) {
			return switch binary.Operator {
				case Add | Subtract | Multiply | Divide | Modulo:
					final left = TypeOf(binary.Left);
					left.match(SqlUnknown) ? TypeOf(binary.Right) : left;
				case _: SqlBool;
			}
		}
		final casted = Std.downcast(cast e, SqlCastExpression);
		if (casted != null) {
			return casted.Type;
		}
		final aggregate = Std.downcast(cast e, AggregateSqlExpression);
		if (aggregate != null) {
			return switch aggregate.Type {
				case Count: SqlInt;
				case Avg: SqlFloat;
				case _: TypeOf(aggregate.Argument);
			}
		}
		final chosen = Std.downcast(cast e, CaseSqlExpression);
		if (chosen != null) {
			for (branch in chosen.Branches) {
				final type = TypeOf(branch.Then);
				if (!type.match(SqlUnknown)) {
					return type;
				}
			}
			return TypeOf(chosen.Otherwise);
		}
		if (Std.isOfType(e, NotSqlExpression) || Std.isOfType(e, InSqlExpression) || Std.isOfType(e, BetweenSqlExpression)
			|| Std.isOfType(e, ExistsSqlExpression) || Std.isOfType(e, IsDistinctFromSqlExpression)
			|| Std.isOfType(e, StringOperationExpression) || Std.isOfType(e, QuantifiedComparisonSqlExpression)) {
			return SqlBool;
		}
		final windowed = Std.downcast(cast e, WindowFunctionExpression);
		if (windowed != null) {
			return switch windowed.Function {
				case RowNumber | Rank | DenseRank | Ntile: SqlInt;
				case PercentRank | CumeDist: SqlFloat;
				case _: windowed.Arguments.length > 0 ? TypeOf(windowed.Arguments[0]) : SqlUnknown;
			}
		}
		return SqlUnknown;
	}

	static function TypeOfValue(value:SqlConstValue):SqlType {
		return switch value {
			case SqlConstBool(_): SqlBool;
			case SqlConstInt(_): SqlInt;
			case SqlConstFloat(_): SqlFloat;
			case SqlConstString(_): SqlText;
			case SqlConstDate(_): SqlTimestamp;
			case SqlConstNull: SqlUnknown;
		}
	}
}
