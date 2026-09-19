package codequery.sqldrivers;

import codequery.sqlexpressions.SqlParameterExpression;

/**
	Renders a statement with its values written in, so it stands alone.

	By default a value sent beside a statement renders as a placeholder, which is the SQL that goes
	to the database. Normalized — C#'s `ToSql(config, normalize: true)` — the values are written
	back in, for whoever reads the statement in a log or a test, where there is nothing beside it.
**/
class NormalizedSqlTranslator extends SqlTranslator {
	public function new() {
		super();
	}

	override public function OnParameter(e:SqlParameterExpression):String {
		return RenderConst(e.Value);
	}
}
