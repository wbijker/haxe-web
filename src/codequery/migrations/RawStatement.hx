package codequery.migrations;

import codequery.sqlexpressions.ISqlStatement;

/**
	A statement already written out.

	A migration is written as text and kept as text, so there is nothing to render — what it needs
	is a way past the renderer, which is what this is.
**/
class RawStatement implements ISqlStatement {
	public final Sql:String;

	public function new(sql:String) {
		this.Sql = sql;
	}
}
