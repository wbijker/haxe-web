package codequery.sqldrivers;

import codequery.sqlexpressions.ISqlStatement;
import codequery.sqlexpressions.SqlConstValue;

/**
	Renders a statement as SQL.

	The half of a driver that has nothing to do with where the SQL goes — which is why it is
	separate: a statement can be rendered with no connection anywhere near it.
**/
interface ISqlTranslator {
	/** The statement as SQL, in this dialect. */
	function ToSql(statement:ISqlStatement):String;

	/** What was sent beside the last statement rendered, in placeholder order. */
	var Parameters(default, null):Array<SqlConstValue>;

	/** How a value sent beside the statement is written into it. */
	function Placeholder(ordinal:Int):String;

	/** One schema change as the DDL that makes it. */
	function ToDdl(change:codequery.migrations.SchemaChange):String;

	/** A schema change expression as DDL; `pretty` lays a CREATE TABLE out one column a line. */
	function ToDdlSql(change:codequery.sqlexpressions.SchemaChangeExpression, pretty:Bool = false):String;

	/** The table the migration runner records what it has applied in, as this dialect creates it. */
	function MigrationHistoryDdl(table:String):String;
}
