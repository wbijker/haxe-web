package codequery.runtimes.php;

import codequery.execution.IDatabaseExecutor;
import codequery.execution.Statement;
import codequery.sqlexpressions.SqlConstValue;
#if php
import php.NativeArray;
import php.NativeAssocArray;
import php.db.PDO;
#end

/**
	Runs a statement through PHP's PDO.

	The first runtime that actually runs anything. Everything up to here renders; this is the two
	methods that carry the result to a database and bring rows back.

	Values are bound rather than written into the SQL, which is what the parameters were for: the
	statement sent is the same whatever the values, and a value never has to be escaped because it
	never becomes text.
**/
class PdoExecutor implements IDatabaseExecutor {
	#if php
	final connection:PDO;

	public function new(connection:PDO) {
		this.connection = connection;
	}

	/** Opens a connection from a DSN, e.g. `sqlite::memory:` or `pgsql:host=…;dbname=…`. */
	public static function Connect(dsn:String, ?user:String, ?password:String):PdoExecutor {
		final connection = new PDO(dsn, user, password);
		connection.setAttribute(PDO.ATTR_ERRMODE, PDO.ERRMODE_EXCEPTION);
		return new PdoExecutor(connection);
	}

	public function Query(statement:Statement):Array<Map<String, Dynamic>> {
		final prepared = connection.prepare(statement.Sql);
		prepared.execute(Bound(statement.Parameters));

		// A row comes back as a PHP associative array, which is not a Haxe object: its keys are
		// reachable by asking PHP for them, not by reflecting over fields.
		final rows:Array<Map<String, Dynamic>> = [];
		for (row in php.Lib.toHaxeArray(prepared.fetchAll(PDO.FETCH_ASSOC))) {
			rows.push(php.Lib.hashOfAssociativeArray(cast row));
		}
		return rows;
	}

	public function NonQuery(statement:Statement):Int {
		final prepared = connection.prepare(statement.Sql);
		prepared.execute(Bound(statement.Parameters));
		return prepared.rowCount();
	}

	/** Runs SQL this port does not build — creating the tables a test needs, and the like. */
	public function Raw(sql:String):Void {
		connection.exec(sql);
	}

	/** The values as PDO takes them: positionally, in the order their placeholders were numbered. */
	function Bound(parameters:Array<SqlConstValue>):NativeArray {
		return php.Lib.toPhpArray([
			for (parameter in parameters)
				switch parameter {
					case SqlConstBool(v): v ? 1 : 0;
					case SqlConstInt(v): v;
					case SqlConstFloat(v): v;
					case SqlConstString(v): v;
					case SqlConstDate(v): DateTools.format(v, "%Y-%m-%d %H:%M:%S");
					case SqlConstNull: null;
				}
		]);
	}
	#else
	public function new() {
		throw "PdoExecutor runs on the PHP target; this one is not it.";
	}

	public function Query(statement:Statement):Array<Map<String, Dynamic>> {
		return throw "PdoExecutor runs on the PHP target";
	}

	public function NonQuery(statement:Statement):Int {
		return throw "PdoExecutor runs on the PHP target";
	}
	#end
}
