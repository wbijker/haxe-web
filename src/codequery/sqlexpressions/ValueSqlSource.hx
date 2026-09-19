package codequery.sqlexpressions;

/**
	A constant table — `(VALUES (1, 'a'), (2, 'b')) AS t0(id, name)` — as a statement's source.

	What `SqlValues` builds: rows of values written into the statement, named as columns, so a list
	held in memory can be selected from, joined to, or looked up with IN like any table.
**/
class ValueSqlSource implements ISqlSource {
	public final Rows:Array<Array<ISqlExpression>>;
	public final ColumnNames:Array<String>;
	public var Alias(default, null):String;

	public function new(rows:Array<Array<ISqlExpression>>, columnNames:Array<String>, alias:String) {
		this.Rows = rows;
		this.ColumnNames = columnNames;
		this.Alias = alias;
	}
}
