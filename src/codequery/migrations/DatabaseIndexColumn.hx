package codequery.migrations;

class DatabaseIndexColumn {
	public var ColumnName:String;
	public var SortOrder:DatabaseSortOrder;

	public function new(columnName:String = "", ?sortOrder:DatabaseSortOrder) {
		this.ColumnName = columnName;
		this.SortOrder = sortOrder == null ? Ascending : sortOrder;
	}

	public function Equals(other:DatabaseIndexColumn):Bool {
		return other != null && ColumnName == other.ColumnName && SortOrder == other.SortOrder;
	}
}
