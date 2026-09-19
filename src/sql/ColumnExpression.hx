package sql;

/** A column reference, e.g. `d.Id`. */
class ColumnExpression extends SqlExpression {
	public final table:String;
	public final name:String;

	public function new(table:String, name:String) {
		super();
		this.table = table;
		this.name = name;
	}

	public function toSql():String {
		return '$table.$name';
	}

	public function describe(indent:String = ""):String {
		return '${indent}ColumnExpression($table.$name)';
	}
}
