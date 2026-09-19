package codequery.sqlexpressions;

/** A table in a FROM clause, under the alias the query gave it. */
class TableSqlSource implements ISqlSource {
	public final Table:QualifiedTableName;
	public var Alias(default, null):String;

	public function new(table:QualifiedTableName, alias:String) {
		this.Table = table;
		this.Alias = alias;
	}
}
