package sql;

/** A boolean literal, rendered as the SQL Server style `1`/`0`. */
class ConstBoolExpression extends SqlExpression {
	public final value:Bool;

	public function new(value:Bool) {
		super();
		this.value = value;
	}

	public function toSql():String {
		return value ? "1" : "0";
	}

	public function describe(indent:String = ""):String {
		return '${indent}ConstBoolExpression($value)';
	}
}
