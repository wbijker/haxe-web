package codequery.sqldrivers;

import codequery.migrations.DbMigrationStrategy;

/**
	The statements that put a view into the database and take it out, in the port's dialect —
	`CREATE OR REPLACE VIEW`, or a drop and a create when the strategy asks for one. C#'s
	`SqlTranslatorBase.BuildCreateViewSql` and what the PostgreSQL driver adds for a materialized
	view. A dialect that spells these differently overrides the translator's methods, not this.
**/
class ViewStatements {
	public static function Create(name:String, select:String, materialized:Bool, strategy:DbMigrationStrategy):String {
		final kind = Kind(materialized);
		return switch strategy {
			case CreateOrReplace:
				// A materialized view has no replace form at all.
				materialized ? 'CREATE $kind $name AS\n$select' : 'CREATE OR REPLACE VIEW $name AS\n$select';

			case DropThenCreate | DropCascadeThenCreate:
				final cascade = strategy == DropCascadeThenCreate ? " CASCADE" : "";
				'${Drop(name, materialized)}$cascade;\nCREATE $kind $name AS\n$select';

			case CreateIfAbsent:
				'CREATE $kind IF NOT EXISTS $name AS\n$select';

			case RenameSwap:
				// Built beside the one that is there, then renamed into place. The staging view is
				// dropped first, in case a run failed between creating it and renaming it.
				final staging = name + "__new";
				'DROP $kind IF EXISTS $staging;\n'
				+ 'CREATE $kind $staging AS\n$select;\n'
				+ 'DROP $kind IF EXISTS $name;\n'
				+ 'ALTER $kind $staging RENAME TO $name';

			case DropCascadeThenRestore:
				throw "DropCascadeThenRestore reads a view's dependants back out of PostgreSQL's catalogue to "
					+ "put them back, which this dialect has no spelling for; DropCascadeThenCreate drops them.";
		}
	}

	/** `DROP VIEW IF EXISTS`, with its own keyword for a materialized view. */
	public static function Drop(name:String, materialized:Bool):String {
		return 'DROP ${Kind(materialized)} IF EXISTS $name';
	}

	static function Kind(materialized:Bool):String {
		return materialized ? "MATERIALIZED VIEW" : "VIEW";
	}
}
