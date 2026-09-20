package codequery.sqlexpressions;

/** A CREATE TABLE on its own, for a driver to render — the C# `TableCreateExpression`. */
class TableCreateExpression implements ISqlStatement {
	public final TableName:String;
	public final Columns:Array<ColumnDefinition>;
	public final Constraints:Array<TableConstraint>;
	public final IfNotExists:Bool;

	public function new(tableName:String, columns:Array<ColumnDefinition>, ?constraints:Array<TableConstraint>,
			ifNotExists:Bool = false) {
		this.TableName = tableName;
		this.Columns = columns;
		this.Constraints = constraints == null ? [] : constraints;
		this.IfNotExists = ifNotExists;
	}
}
