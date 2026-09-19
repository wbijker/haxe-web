package codequery.sqlexpressions;

/**
	One change to a schema, as the C# classes of the same names say it.

	A statement as well as an expression: a driver renders one straight to DDL, which is what a
	migration is a list of.
**/
class SchemaChangeExpression implements ISqlExpression implements ISqlStatement {
	public final ChangeType:SchemaChangeType;

	function new(changeType:SchemaChangeType) {
		this.ChangeType = changeType;
	}
}

enum SchemaChangeType {
	CreateTable;
	DropTable;
	RenameTable;
	AddColumn;
	DropColumn;
	AlterColumn;
	RenameColumn;
	AddConstraint;
	DropConstraint;
	CreateIndex;
	DropIndex;
	RenameIndex;
	CreateSequence;
	DropSequence;
}

class CreateTableExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final Columns:Array<ColumnDefinition>;
	public final Constraints:Array<TableConstraint>;
	public final IfNotExists:Bool;

	public function new(tableName:String, columns:Array<ColumnDefinition>, ?constraints:Array<TableConstraint>,
			?schema:String, ifNotExists:Bool = false) {
		super(CreateTable);
		this.TableName = tableName;
		this.Schema = schema;
		this.Columns = columns;
		this.Constraints = constraints == null ? [] : constraints;
		this.IfNotExists = ifNotExists;
	}
}

class DropTableExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final IfExists:Bool;
	public final Cascade:Bool;

	public function new(tableName:String, ?schema:String, ifExists:Bool = false, cascade:Bool = false) {
		super(DropTable);
		this.TableName = tableName;
		this.Schema = schema;
		this.IfExists = ifExists;
		this.Cascade = cascade;
	}
}

class RenameTableExpression extends SchemaChangeExpression {
	public final OldTableName:String;
	public final NewTableName:String;
	public final Schema:Null<String>;

	public function new(oldTableName:String, newTableName:String, ?schema:String) {
		super(RenameTable);
		this.OldTableName = oldTableName;
		this.NewTableName = newTableName;
		this.Schema = schema;
	}
}

class AddColumnExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final Column:ColumnDefinition;

	/** What rows already there take, for a NOT NULL column arriving where rows are. */
	public final Backfill:Null<ISqlExpression>;

	public function new(tableName:String, column:ColumnDefinition, ?schema:String, ?backfill:ISqlExpression) {
		super(AddColumn);
		this.TableName = tableName;
		this.Schema = schema;
		this.Column = column;
		this.Backfill = backfill;
	}
}

class DropColumnExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final ColumnName:String;
	public final Cascade:Bool;

	public function new(tableName:String, columnName:String, ?schema:String, cascade:Bool = false) {
		super(DropColumn);
		this.TableName = tableName;
		this.Schema = schema;
		this.ColumnName = columnName;
		this.Cascade = cascade;
	}
}

class AlterColumnExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final ColumnName:String;
	public final NewDefinition:ColumnDefinition;
	public final OldDefinition:Null<ColumnDefinition>;

	public function new(tableName:String, columnName:String, newDefinition:ColumnDefinition,
			?oldDefinition:ColumnDefinition, ?schema:String) {
		super(AlterColumn);
		this.TableName = tableName;
		this.Schema = schema;
		this.ColumnName = columnName;
		this.NewDefinition = newDefinition;
		this.OldDefinition = oldDefinition;
	}
}

class RenameColumnExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final OldColumnName:String;
	public final NewColumnName:String;

	public function new(tableName:String, oldColumnName:String, newColumnName:String, ?schema:String) {
		super(RenameColumn);
		this.TableName = tableName;
		this.Schema = schema;
		this.OldColumnName = oldColumnName;
		this.NewColumnName = newColumnName;
	}
}

class AddConstraintExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final Constraint:TableConstraint;

	public function new(tableName:String, constraint:TableConstraint, ?schema:String) {
		super(AddConstraint);
		this.TableName = tableName;
		this.Schema = schema;
		this.Constraint = constraint;
	}
}

class DropConstraintExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final ConstraintName:String;
	public final Cascade:Bool;

	public function new(tableName:String, constraintName:String, ?schema:String, cascade:Bool = false) {
		super(DropConstraint);
		this.TableName = tableName;
		this.Schema = schema;
		this.ConstraintName = constraintName;
		this.Cascade = cascade;
	}
}

class CreateIndexExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final IndexName:String;
	public final Columns:Array<IndexColumnDefinition>;
	public final IsUnique:Bool;
	public final IsClustered:Bool;
	public final FilterExpression:Null<String>;
	public final IfNotExists:Bool;
	public final IncludeColumns:Array<String>;
	public final Method:Null<String>;

	public function new(tableName:String, indexName:String, columns:Array<IndexColumnDefinition>,
			isUnique:Bool = false, isClustered:Bool = false, ?filterExpression:String, ?schema:String,
			ifNotExists:Bool = false, ?includeColumns:Array<String>, ?method:String) {
		super(CreateIndex);
		this.TableName = tableName;
		this.Schema = schema;
		this.IndexName = indexName;
		this.Columns = columns;
		this.IsUnique = isUnique;
		this.IsClustered = isClustered;
		this.FilterExpression = filterExpression;
		this.IfNotExists = ifNotExists;
		this.IncludeColumns = includeColumns == null ? [] : includeColumns;
		this.Method = method;
	}
}

/** One column of an index, and which way it is read. */
class IndexColumnDefinition {
	public final ColumnName:String;
	public final Descending:Bool;

	public function new(columnName:String, descending:Bool = false) {
		this.ColumnName = columnName;
		this.Descending = descending;
	}
}

class DropIndexExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final IndexName:String;
	public final IfExists:Bool;
	public final Cascade:Bool;

	public function new(tableName:String, indexName:String, ?schema:String, ifExists:Bool = false,
			cascade:Bool = false) {
		super(DropIndex);
		this.TableName = tableName;
		this.Schema = schema;
		this.IndexName = indexName;
		this.IfExists = ifExists;
		this.Cascade = cascade;
	}
}

class RenameIndexExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final OldIndexName:String;
	public final NewIndexName:String;

	public function new(tableName:String, oldIndexName:String, newIndexName:String, ?schema:String) {
		super(RenameIndex);
		this.TableName = tableName;
		this.Schema = schema;
		this.OldIndexName = oldIndexName;
		this.NewIndexName = newIndexName;
	}
}

/** A standalone sequence generator. */
class CreateSequenceExpression extends SchemaChangeExpression {
	public final Name:String;
	public final Schema:Null<String>;
	public final StartWith:Int;
	public final IncrementBy:Int;
	public final MinValue:Null<Int>;
	public final MaxValue:Null<Int>;
	public final Cycle:Bool;
	public final IfNotExists:Bool;

	public function new(name:String, startWith:Int = 1, incrementBy:Int = 1, ?minValue:Int, ?maxValue:Int,
			cycle:Bool = false, ?schema:String, ifNotExists:Bool = false) {
		super(CreateSequence);
		this.Name = name;
		this.Schema = schema;
		this.StartWith = startWith;
		this.IncrementBy = incrementBy;
		this.MinValue = minValue;
		this.MaxValue = maxValue;
		this.Cycle = cycle;
		this.IfNotExists = ifNotExists;
	}
}

class DropSequenceExpression extends SchemaChangeExpression {
	public final Name:String;
	public final Schema:Null<String>;
	public final IfExists:Bool;

	public function new(name:String, ?schema:String, ifExists:Bool = false) {
		super(DropSequence);
		this.Name = name;
		this.Schema = schema;
		this.IfExists = ifExists;
	}
}
