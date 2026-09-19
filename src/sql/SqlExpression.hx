package sql;

/** Base class for every node in the SQL expression tree. */
abstract class SqlExpression {
	public function new() {}

	/** Render this node as SQL. */
	public abstract function toSql():String;
}
