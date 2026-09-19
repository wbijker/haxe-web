package codequery.migrations;

import codequery.sqlexpressions.SchemaChangeExpression;

/** What has to happen to turn one schema into another. */
class SchemaDiff {
	/**
		The changes from `from` to `to`.

		Tables are created before columns are added to them and dropped whole, so the list can be
		applied in the order it comes in.
	**/
	public static function Between(from:DatabaseSchema, to:DatabaseSchema):Array<SchemaChangeExpression> {
		return to.Diff(from);
	}
}
