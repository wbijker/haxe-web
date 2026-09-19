package codequery.execution;

import codequery.sqldrivers.SqlDriver;
import codequery.sqlexpressions.ISqlStatement;

/**
	What a query needs to run: something to render it, and something to run what was rendered.

	A query built without one can still be rendered — which is all this port does today — and only
	asking it to run needs the second half.
**/
class DatabaseConfiguration {
	public final Driver:SqlDriver;
	public final Executor:Null<IDatabaseExecutor>;

	public function new(driver:SqlDriver, ?executor:IDatabaseExecutor) {
		this.Driver = driver;
		this.Executor = executor;
	}

	/** Renders a statement, with the values that go beside it. */
	public function Render(statement:ISqlStatement):Statement {
		final sql = Driver.ToSql(statement);
		return {Sql: sql, Parameters: Driver.Parameters};
	}

	/** Runs a statement that changes rows, and answers with how many it changed. */
	public function Execute(statement:ISqlStatement):Int {
		return Require().NonQuery(Render(statement));
	}

	/** Runs a statement that answers with rows. */
	public function Fetch(statement:ISqlStatement):Array<Map<String, Dynamic>> {
		return Require().Query(Render(statement));
	}

	function Require():IDatabaseExecutor {
		if (Executor == null) {
			throw "This configuration renders but does not run: it was built without an executor.";
		}
		return Executor;
	}
}
