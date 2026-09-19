package sql;

/** A string literal. Quotes are escaped SQL-style, by doubling them. */
class ConstStringExpression extends SqlExpression {
	public final value:String;

	public function new(value:String) {
		super();
		this.value = value;
	}

	public function toSql():String {
		return "'" + StringTools.replace(value, "'", "''") + "'";
	}
}
