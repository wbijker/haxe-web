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
}
