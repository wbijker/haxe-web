package codequery.migrations;

/** One column of an index, and which way it sorts — the C# `DatabaseIndexColumn`. */
class DatabaseIndexColumn {
	public var ColumnName:String;
	public var SortOrder:DatabaseSortOrder;

	public function new(columnName:String, ?sortOrder:DatabaseSortOrder) {
		this.ColumnName = columnName;
		this.SortOrder = sortOrder == null ? Ascending : sortOrder;
	}

	public function Equals(other:DatabaseIndexColumn):Bool {
		return other != null && ColumnName == other.ColumnName && Std.string(SortOrder) == Std.string(other.SortOrder);
	}
}
