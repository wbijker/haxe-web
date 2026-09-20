package codequery.execution;

import codequery.sqldrivers.ISqlTranslator;
import codequery.sqlexpressions.ISqlStatement;

/**
	What a query needs to run: something to render it, and something to run what was rendered.

	A query built without one can still be rendered — which is all this port does today — and only
	asking it to run needs the second half.
**/
class DatabaseConfiguration {
	public final Driver:ISqlTranslator;
	public final Executor:Null<IDatabaseExecutor>;

	/** The folder migrations are written to and read from — named, not located. */
	public final MigrationFolder:Null<String>;

	public function new(driver:ISqlTranslator, ?executor:IDatabaseExecutor, ?migrationFolder:String) {
		this.Driver = driver;
		this.Executor = executor;
		this.MigrationFolder = migrationFolder;
	}

	/** The same configuration, with its migrations in `folder`. */
	public function WithMigrations(folder:String):DatabaseConfiguration {
		return new DatabaseConfiguration(Driver, Executor, folder);
	}

	/** The same, taken whole from a driver that carries both halves. */
	public static function Of(driver:codequery.sqldrivers.ISqlDriver):DatabaseConfiguration {
		return new DatabaseConfiguration(driver, driver.Executor());
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
