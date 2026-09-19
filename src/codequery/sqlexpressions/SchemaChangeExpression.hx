package codequery.sqlexpressions;

/** The kinds of object a routine can be. */
enum DatabaseRoutineKind {
	Function;
	Procedure;
	View;
	Trigger;
}

/** The kind of a seed-data row change. */
enum SeedOperation {
	Insert;
	Update;
	Delete;
}

/**
	A change to the schema, as a statement a driver renders: the C# `SchemaChangeExpression`
	hierarchy. Each is data about the change and nothing about any dialect.
**/
class SchemaChangeExpression implements ISqlStatement {
	function new() {}
}

class CreateTableExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final Columns:Array<ColumnDefinition>;
	public final Constraints:Array<TableConstraint>;
	public final IfNotExists:Bool;
	public final Partition:Null<TablePartition>;

	/** `CREATE TEMPORARY TABLE` — gone when the session is. */
	public var Temporary:Bool = false;

	/** `CREATE UNLOGGED TABLE` — not written to the log, so faster and not crash-safe. */
	public var Unlogged:Bool = false;

	public function new(tableName:String, columns:Array<ColumnDefinition>, ?constraints:Array<TableConstraint>,
			?schema:String, ifNotExists:Bool = false, ?partition:TablePartition) {
		super();
		this.TableName = tableName;
		this.Columns = columns;
		this.Constraints = constraints == null ? [] : constraints;
		this.Schema = schema;
		this.IfNotExists = ifNotExists;
		this.Partition = partition;
	}
}

class DropTableExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final IfExists:Bool;
	public final Cascade:Bool;

	public function new(tableName:String, ?schema:String, ifExists:Bool = false, cascade:Bool = false) {
		super();
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
		super();
		this.OldTableName = oldTableName;
		this.NewTableName = newTableName;
		this.Schema = schema;
	}
}

class AddColumnExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final Column:ColumnDefinition;

	/**
		What the rows already in the table take, for a NOT NULL column arriving where rows are — written
		in and taken off again. Null where nothing is needed.
	**/
	public final Backfill:Null<ISqlExpression>;

	public function new(tableName:String, column:ColumnDefinition, ?schema:String, ?backfill:ISqlExpression) {
		super();
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
		super();
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
		super();
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
		super();
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
		super();
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
		super();
		this.TableName = tableName;
		this.Schema = schema;
		this.ConstraintName = constraintName;
		this.Cascade = cascade;
	}
}

/** One column of an index, and which way it runs. */
class IndexColumnDefinition {
	public final ColumnName:String;
	public final Descending:Bool;

	public function new(columnName:String, descending:Bool = false) {
		this.ColumnName = columnName;
		this.Descending = descending;
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

	/** Non-key columns stored in the index leaf (`INCLUDE (...)`). */
	public final IncludeColumns:Array<String>;

	/** The index access method (`USING gin` / `gist` / …). Null is the default, btree. */
	public final Method:Null<String>;

	public function new(tableName:String, indexName:String, columns:Array<IndexColumnDefinition>, isUnique:Bool = false,
			isClustered:Bool = false, ?filterExpression:String, ?schema:String, ifNotExists:Bool = false,
			?includeColumns:Array<String>, ?method:String) {
		super();
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

class DropIndexExpression extends SchemaChangeExpression {
	public final TableName:String;
	public final Schema:Null<String>;
	public final IndexName:String;
	public final IfExists:Bool;
	public final Cascade:Bool;

	public function new(tableName:String, indexName:String, ?schema:String, ifExists:Bool = false, cascade:Bool = false) {
		super();
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
		super();
		this.TableName = tableName;
		this.Schema = schema;
		this.OldIndexName = oldIndexName;
		this.NewIndexName = newIndexName;
	}
}

class DropTypeExpression extends SchemaChangeExpression {
	public final TypeName:String;
	public final Schema:Null<String>;
	public final IfExists:Bool;
	public final IsDomain:Bool;
	public final Cascade:Bool;

	public function new(typeName:String, ?schema:String, ifExists:Bool = false, isDomain:Bool = false, cascade:Bool = false) {
		super();
		this.TypeName = typeName;
		this.Schema = schema;
		this.IfExists = ifExists;
		this.IsDomain = isDomain;
		this.Cascade = cascade;
	}
}

/** Drops a function, view, procedure or trigger. */
class DropRoutineExpression extends SchemaChangeExpression {
	public final Kind:DatabaseRoutineKind;
	public final Name:String;
	public final Schema:Null<String>;
	public final Cascade:Bool;

	/** For a trigger, the table it fires on. */
	public final Table:Null<String>;

	public function new(kind:DatabaseRoutineKind, name:String, ?schema:String, cascade:Bool = false, ?table:String) {
		super();
		this.Kind = kind;
		this.Name = name;
		this.Schema = schema;
		this.Cascade = cascade;
		this.Table = table;
	}
}

/** Creates (or replaces) a routine from the SQL its schema recorded for it. */
class CreateRoutineExpression extends SchemaChangeExpression {
	public final Kind:DatabaseRoutineKind;
	public final Name:String;
	public final Schema:Null<String>;
	public final Body:Null<String>;

	public function new(kind:DatabaseRoutineKind, name:String, ?schema:String, ?body:String) {
		super();
		this.Kind = kind;
		this.Name = name;
		this.Schema = schema;
		this.Body = body;
	}
}

/** A single seed-data row change (INSERT / UPDATE / DELETE) keyed by the primary key. */
class SeedDataExpression extends SchemaChangeExpression {
	public final Operation:SeedOperation;
	public final TableName:String;
	public final Schema:Null<String>;
	public final Columns:Array<String>;
	public final KeyColumns:Array<String>;

	/** Column name → SQL literal for this row. */
	public final Values:Map<String, String>;

	public function new(operation:SeedOperation, tableName:String, ?schema:String, columns:Array<String>,
			keyColumns:Array<String>, values:Map<String, String>) {
		super();
		this.Operation = operation;
		this.TableName = tableName;
		this.Schema = schema;
		this.Columns = columns;
		this.KeyColumns = keyColumns;
		this.Values = values;
	}
}

/** SQL that was already rendered when the schema was built — the driver emits it verbatim. */
class StatementExpression extends SchemaChangeExpression {
	public final Name:String;
	public final Sql:String;
	public final IsUndo:Bool;

	public function new(name:String, sql:String, isUndo:Bool = false) {
		super();
		this.Name = name;
		this.Sql = sql;
		this.IsUndo = isUndo;
	}
}
