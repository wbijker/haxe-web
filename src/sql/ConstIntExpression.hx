package sql;

/** An integer literal, e.g. `10`. */
class ConstIntExpression extends SqlExpression {
	public final value:Int;

	public function new(value:Int) {
		super();
		this.value = value;
	}

	public function toSql():String {
		return Std.string(value);
	}
}
