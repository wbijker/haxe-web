package codequery.migrations;

import codequery.sqlexpressions.SchemaChangeExpression;

/** An index as the schema records it. */
class DatabaseIndexDefinition {
	public var Name:String;
	public var Columns:Array<DatabaseIndexColumn>;
	public var IsUnique:Bool = false;
	public var IsClustered:Bool = false;
	public var FilterExpression:Null<String> = null;
	public var IncludeColumns:Array<String> = [];
	public var Method:Null<String> = null;

	public function new(name:String = "", ?columns:Array<DatabaseIndexColumn>, isUnique:Bool = false, isClustered:Bool = false,
			?filterExpression:String, ?method:String) {
		this.Name = name;
		this.Columns = columns == null ? [] : columns;
		this.IsUnique = isUnique;
		this.IsClustered = isClustered;
		this.FilterExpression = filterExpression;
		this.Method = method;
	}

	public function ToCreateIndexExpression(tableName:String, ?schema:String, ifNotExists:Bool = false):CreateIndexExpression {
		final columns = [for (c in Columns) new IndexColumnDefinition(c.ColumnName, c.SortOrder == Descending)];
		return new CreateIndexExpression(tableName, Name, columns, IsUnique, IsClustered, FilterExpression, schema,
			ifNotExists, IncludeColumns.copy(), Method);
	}

	/** An index is more than its columns: the method and the included columns are part of what it is. */
	public function Equals(other:DatabaseIndexDefinition):Bool {
		if (other == null || Name != other.Name || IsUnique != other.IsUnique || IsClustered != other.IsClustered
			|| FilterExpression != other.FilterExpression || Method != other.Method
			|| IncludeColumns.join("\n") != other.IncludeColumns.join("\n")
			|| Columns.length != other.Columns.length) {
			return false;
		}
		for (index in 0...Columns.length) {
			if (!Columns[index].Equals(other.Columns[index])) {
				return false;
			}
		}
		return true;
	}

	public function Clone():DatabaseIndexDefinition {
		final copy = new DatabaseIndexDefinition(Name, [for (c in Columns) new DatabaseIndexColumn(c.ColumnName, c.SortOrder)]);
		copy.IsUnique = IsUnique;
		copy.IsClustered = IsClustered;
		copy.FilterExpression = FilterExpression;
		copy.IncludeColumns = IncludeColumns.copy();
		copy.Method = Method;
		return copy;
	}
}
