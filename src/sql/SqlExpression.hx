package sql;

/** Base class for every node in the SQL expression tree. */
abstract class SqlExpression {
	public function new() {}

	/** Render this node as SQL. */
	public abstract function toSql():String;

	/** Render this node as an indented tree, for debugging macros. */
	public abstract function describe(indent:String = ""):String;
}
