package codequery.migrations;

import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.RawSqlExpression;

/**
	What the rows already in a table take when a NOT NULL column is added to it.

	A column arriving without a default has no value for the rows that are already there, and the
	database refuses the statement rather than inventing one. So one is written in — the type's own
	zero — and taken off again once the rows have it. A column the schema does default needs none of
	this, which is why this asks only about columns that have none.
**/
class ColumnBackfill {
	/** The value existing rows take, or null where the column needs no help. */
	public static function For(column:ColumnDefinition):Null<ISqlExpression> {
		if (column.IsNullable || column.DefaultValue != null || column.IsAutoIncrement) {
			return null;
		}
		return Zero(column);
	}

	/**
		The type's zero: false, 0, an empty string, the first instant, an empty Guid. Null for the
		types where nothing is obviously empty — a document, a blob — and for a time of day.
	**/
	static function Zero(column:ColumnDefinition):Null<ISqlExpression> {
		return switch column.Type {
			case SqlBool: new ConstSqlExpression(SqlConstBool(false));
			case SqlInt | SqlBigInt | SqlSmallInt: new ConstSqlExpression(SqlConstInt(0));
			case SqlFloat | SqlReal | SqlDecimal(_, _): new ConstSqlExpression(SqlConstInt(0));
			case SqlText | SqlVarChar(_) | SqlChar(_): new ConstSqlExpression(SqlConstString(""));
			case SqlTimestamp | SqlDate: new RawSqlExpression("'0001-01-01 00:00:00'");
			case SqlGuid: new ConstSqlExpression(SqlConstString("00000000-0000-0000-0000-000000000000"));
			case SqlJson | SqlBinary | SqlTime | SqlUnknown | SqlNamed(_): null;
		}
	}
}
