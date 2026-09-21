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

	/** Told of every statement sent, or null where nothing listens. */
	public final Logger:Null<codequery.ISqlLogger>;

	public function new(driver:ISqlTranslator, ?executor:IDatabaseExecutor, ?migrationFolder:String, ?logger:codequery.ISqlLogger) {
		this.Driver = driver;
		this.Executor = executor;
		this.MigrationFolder = migrationFolder;
		this.Logger = logger;
	}

	/** The same configuration, with its migrations in `folder`. */
	public function WithMigrations(folder:String):DatabaseConfiguration {
		return new DatabaseConfiguration(Driver, Executor, folder, Logger);
	}

	/** The same configuration, with `logger` told of every statement it sends. */
	public function WithLogger(logger:codequery.ISqlLogger):DatabaseConfiguration {
		if (logger == null) {
			throw "WithLogger needs a logger";
		}
		return new DatabaseConfiguration(Driver, Executor, MigrationFolder, logger);
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
		final executor = Require();
		final rendered = Render(statement);
		return Sending(rendered, () -> executor.NonQuery(rendered), affected -> new SqlOutcome(null, affected, 0));
	}

	/** Runs a statement that answers with rows. */
	public function Fetch(statement:ISqlStatement):Array<Map<String, Dynamic>> {
		final executor = Require();
		final rendered = Render(statement);
		return Sending(rendered, () -> executor.Query(rendered), rows -> new SqlOutcome(rows.length, null, 0));
	}

	/** Sends a statement past the logger, if there is one: told before, and after with what came back or what went wrong. */
	function Sending<T>(rendered:Statement, send:Void->T, outcome:T->SqlOutcome):T {
		if (Logger == null) {
			return send();
		}
		final query = new SqlQuery(rendered, Driver.Placeholder, SqlQuery.CallSite());
		Logger.BeforeSend(query);
		final started = haxe.Timer.stamp();
		try {
			final answer = send();
			final came = outcome(answer);
			Logger.AfterSend(query, new SqlOutcome(came.Rows, came.Affected, (haxe.Timer.stamp() - started) * 1000));
			return answer;
		} catch (e:Dynamic) {
			Logger.AfterSend(query, new SqlOutcome(null, null, (haxe.Timer.stamp() - started) * 1000, Std.string(e)));
			throw e;
		}
	}

	function Require():IDatabaseExecutor {
		if (Executor == null) {
			throw "This configuration renders but does not run: it was built without an executor.";
		}
		return Executor;
	}
}
