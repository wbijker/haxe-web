package codequery.migrations;

/** A value as a SQL literal — what a seed row is written as, so rows compare and diff as text. */
class SqlLiteral {
	public static function Format(value:Dynamic):String {
		if (value == null) {
			return "NULL";
		}
		if (Std.isOfType(value, Bool)) {
			return (value : Bool) ? "TRUE" : "FALSE";
		}
		if (Std.isOfType(value, Int) || Std.isOfType(value, Float)) {
			return Std.string(value);
		}
		if (Std.isOfType(value, Date)) {
			return "'" + DateTools.format(value, "%Y-%m-%d %H:%M:%S") + "'";
		}
		return "'" + StringTools.replace(Std.string(value), "'", "''") + "'";
	}
}
