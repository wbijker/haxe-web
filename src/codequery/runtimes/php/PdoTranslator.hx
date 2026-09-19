package codequery.runtimes.php;

import codequery.sqldrivers.SqlTranslator;

/**
	The dialect as PDO wants it said.

	One difference so far, and it matters: PDO binds the values sent beside a statement by their
	position, marked `?`, where the default translator numbers them `$1`, `$2` as PostgreSQL reads
	them. Send `$1` through PDO and it binds nothing and the statement fails.
**/
class PdoTranslator extends SqlTranslator {
	public function new() {
		super();
	}

	override public function Placeholder(ordinal:Int):String {
		return "?";
	}

	/**
		SQLite, which is what the PHP runtime runs against, has no `CREATE OR REPLACE VIEW`: a view
		is dropped and created again, which is what its replace already means. It cannot cascade a
		drop or rename a view either, so the strategies that need to say so rather than quietly
		doing something else — as the C# SQLite driver does.
	**/
	override public function BuildCreateViewSql(name:String, select:String, materialized:Bool = false,
			?strategy:codequery.migrations.DbMigrationStrategy):String {
		if (materialized) {
			throw "SQLite does not support materialized views.";
		}
		return switch strategy {
			case null | CreateOrReplace | DropThenCreate:
				'${BuildDropViewSql(name)};\nCREATE VIEW $name AS\n$select';
			case CreateIfAbsent:
				'CREATE VIEW IF NOT EXISTS $name AS\n$select';
			case DropCascadeThenCreate | DropCascadeThenRestore:
				throw 'SQLite has no CASCADE on DROP VIEW, so DbMigrationStrategy.$strategy cannot be honoured; use DropThenCreate.';
			case RenameSwap:
				throw "SQLite cannot rename a view, so there is nothing to swap with; use DropThenCreate.";
		}
	}
}
