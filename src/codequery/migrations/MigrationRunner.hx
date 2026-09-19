package codequery.migrations;

import codequery.execution.DatabaseConfiguration;
import codequery.sqlexpressions.SqlConstValue;

/**
	Applies migrations, and remembers which it has.

	What it remembers lives in the database, in a table of its own — the only way a migration can
	know whether it has already run somewhere it did not write.
**/
class MigrationRunner {
	public static final Table = "__codequery_migrations";

	final config:DatabaseConfiguration;
	final store:MigrationStore;

	public function new(config:DatabaseConfiguration, store:MigrationStore) {
		this.config = config;
		this.store = store;
	}

	/** The migrations written but not yet applied, oldest first. */
	public function Pending():Array<Migration> {
		final applied = Applied();
		return store.All().filter(migration -> applied.indexOf(migration.Name) < 0);
	}

	/** The names of those already applied. */
	public function Applied():Array<String> {
		EnsureTable();
		return [
			for (row in config.Fetch(Raw('SELECT name FROM $Table ORDER BY name')))
				Std.string(row.get("name"))
		];
	}

	/** Applies every pending migration, in order, and answers with what it applied. */
	public function Run():Array<String> {
		final ran:Array<String> = [];
		for (migration in Pending()) {
			for (statement in Statements(migration.Up)) {
				config.Execute(Raw(statement));
			}
			config.Execute(Raw('INSERT INTO $Table (name) VALUES (\'${migration.Name}\')'));
			ran.push(migration.Name);
		}
		return ran;
	}

	/** Undoes the last applied migration. */
	public function Rollback():Null<String> {
		final applied = Applied();
		if (applied.length == 0) {
			return null;
		}

		final last = applied[applied.length - 1];
		for (migration in store.All()) {
			if (migration.Name != last) {
				continue;
			}
			for (statement in Statements(migration.Down)) {
				config.Execute(Raw(statement));
			}
			config.Execute(Raw('DELETE FROM $Table WHERE name = \'$last\''));
			return last;
		}
		return null;
	}

	function EnsureTable():Void {
		config.Execute(Raw('CREATE TABLE IF NOT EXISTS $Table (name TEXT PRIMARY KEY)'));
	}

	/** A migration is a script; what runs it takes one statement at a time. */
	static function Statements(sql:String):Array<String> {
		return [
			for (statement in sql.split(";"))
				if (StringTools.trim(statement) != "") StringTools.trim(statement)
		];
	}

	/**
		SQL this port did not build — the migration's own, and the bookkeeping around it.

		A migration is written as text and kept as text, so there is no statement to render; what
		it needs is a way past the renderer, which is what this is.
	**/
	static function Raw(sql:String):RawStatement {
		return new RawStatement(sql);
	}
}
