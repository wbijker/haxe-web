package codequery.migrations;

import codequery.sqlexpressions.SchemaChangeExpression;

/** An index, as the schema describes it. */
class DatabaseIndexDefinition {
	public var Name:String;
	public var Columns:Array<DatabaseIndexColumn>;
	public var IsUnique:Bool;
	public var IsClustered:Bool;
	public var FilterExpression:Null<String>;
	public var IncludeColumns:Array<String> = [];
	public var Method:Null<String>;

	public function new(name:String = "", ?columns:Array<DatabaseIndexColumn>, isUnique:Bool = false,
			isClustered:Bool = false, ?filterExpression:String, ?method:String) {
		this.Name = name;
		this.Columns = columns == null ? [] : columns;
		this.IsUnique = isUnique;
		this.IsClustered = isClustered;
		this.FilterExpression = filterExpression;
		this.Method = method;
	}

	public function ToCreateIndexExpression(tableName:String, ?schema:String, ifNotExists:Bool = false):CreateIndexExpression {
		final columns = Columns.map(c -> new IndexColumnDefinition(c.ColumnName, c.SortOrder == Descending));
		return new CreateIndexExpression(tableName, Name, columns, IsUnique, IsClustered, FilterExpression, schema,
			ifNotExists, IncludeColumns, Method);
	}

	public function Equals(other:DatabaseIndexDefinition):Bool {
		if (other == null) {
			return false;
		}
		if (Name != other.Name || IsUnique != other.IsUnique || IsClustered != other.IsClustered
			|| FilterExpression != other.FilterExpression || Method != other.Method) {
			return false;
		}
		if (IncludeColumns.length != other.IncludeColumns.length || Columns.length != other.Columns.length) {
			return false;
		}
		for (index in 0...IncludeColumns.length) {
			if (IncludeColumns[index] != other.IncludeColumns[index]) {
				return false;
			}
		}
		for (index in 0...Columns.length) {
			if (!Columns[index].Equals(other.Columns[index])) {
				return false;
			}
		}
		return true;
	}
}
