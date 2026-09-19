package codequery.migrations;

import codequery.migrations.DatabaseTableConstraint;
import codequery.migrations.DatabaseIndexDefinition;

import codequery.IdentityKind;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.TableCreateExpression;

/** A table, as the schema describes it — provider-agnostic, serializable, and diffable. */
class DatabaseTableDefinition {
	public var TableName:String;
	public var Schema:Null<String>;
	public var Columns:Array<DatabaseColumnDefinition> = [];
	public var Constraints:Array<DatabaseTableConstraint> = [];
	public var Indexes:Array<DatabaseIndexDefinition> = [];

	public function new(tableName:String = "", ?schema:String) {
		this.TableName = tableName;
		this.Schema = schema;
	}

	public function ToCreateTableExpression(ifNotExists:Bool = false):CreateTableExpression {
		return new CreateTableExpression(TableName, Columns.map(c -> c.ToColumnDefinition()),
			Constraints.map(c -> c.ToTableConstraint()), Schema, ifNotExists);
	}

	public function ToTableCreateExpression(ifNotExists:Bool = false):TableCreateExpression {
		return new TableCreateExpression(TableName, Columns.map(c -> c.ToColumnDefinition()),
			Constraints.map(c -> c.ToTableConstraint()), ifNotExists);
	}

	/** The column of that name, or null. Names compare regardless of case, as a database does. */
	public function FindColumn(name:String):Null<DatabaseColumnDefinition> {
		for (column in Columns) {
			if (column.Name.toLowerCase() == name.toLowerCase()) {
				return column;
			}
		}
		return null;
	}

	/**
		The changes that turn `from` into this table — or, from nothing, the changes that make it.
	**/
	public function Diff(from:Null<DatabaseTableDefinition>):Array<SchemaChangeExpression> {
		final changes:Array<SchemaChangeExpression> = [];

		if (from == null) {
			changes.push(ToCreateTableExpression());
			for (index in Indexes) {
				changes.push(index.ToCreateIndexExpression(TableName, Schema));
			}
			return changes;
		}

		if (from.TableName != TableName) {
			changes.push(new RenameTableExpression(from.TableName, TableName, Schema));
		}

		return changes.concat(DiffColumns(from)).concat(DiffConstraints(from)).concat(DiffIndexes(from));
	}

	function DiffColumns(from:DatabaseTableDefinition):Array<SchemaChangeExpression> {
		final changes:Array<SchemaChangeExpression> = [];

		for (column in from.Columns) {
			if (FindColumn(column.Name) == null) {
				changes.push(new DropColumnExpression(TableName, column.Name, Schema));
			}
		}

		for (column in Columns) {
			if (from.FindColumn(column.Name) == null) {
				changes.push(new AddColumnExpression(TableName, column.ToColumnDefinition(), Schema));
			}
		}

		for (column in Columns) {
			final was = from.FindColumn(column.Name);
			if (was == null || column.Equals(was)) {
				continue;
			}
			// A generated column cannot be altered in place: its whole declaration is re-emitted.
			if (column.GeneratedExpression != null || was.GeneratedExpression != null) {
				changes.push(new DropColumnExpression(TableName, column.Name, Schema));
				changes.push(new AddColumnExpression(TableName, column.ToColumnDefinition(), Schema));
			} else {
				changes.push(new AlterColumnExpression(TableName, column.Name, column.ToColumnDefinition(),
					was.ToColumnDefinition(), Schema));
			}
		}

		return changes;
	}

	static function ConstraintNamed(constraints:Array<DatabaseTableConstraint>, name:String):Null<DatabaseTableConstraint> {
		for (constraint in constraints) {
			if (constraint.Name != null && constraint.Name.toLowerCase() == name.toLowerCase()) {
				return constraint;
			}
		}
		return null;
	}

	function DiffConstraints(from:DatabaseTableDefinition):Array<SchemaChangeExpression> {
		final changes:Array<SchemaChangeExpression> = [];

		for (constraint in from.Constraints) {
			if (constraint.Name != null && ConstraintNamed(Constraints, constraint.Name) == null) {
				changes.push(new DropConstraintExpression(TableName, constraint.Name, Schema));
			}
		}

		for (constraint in Constraints) {
			if (constraint.Name != null && ConstraintNamed(from.Constraints, constraint.Name) == null) {
				changes.push(new AddConstraintExpression(TableName, constraint.ToTableConstraint(), Schema));
			}
		}

		for (constraint in Constraints) {
			if (constraint.Name == null) {
				continue;
			}
			final was = ConstraintNamed(from.Constraints, constraint.Name);
			if (was != null && !constraint.Equals(was)) {
				changes.push(new DropConstraintExpression(TableName, constraint.Name, Schema));
				changes.push(new AddConstraintExpression(TableName, constraint.ToTableConstraint(), Schema));
			}
		}

		return changes;
	}

	static function IndexNamed(indexes:Array<DatabaseIndexDefinition>, name:String):Null<DatabaseIndexDefinition> {
		for (index in indexes) {
			if (index.Name.toLowerCase() == name.toLowerCase()) {
				return index;
			}
		}
		return null;
	}

	function DiffIndexes(from:DatabaseTableDefinition):Array<SchemaChangeExpression> {
		final changes:Array<SchemaChangeExpression> = [];

		for (index in from.Indexes) {
			if (IndexNamed(Indexes, index.Name) == null) {
				changes.push(new DropIndexExpression(TableName, index.Name, Schema));
			}
		}

		for (index in Indexes) {
			if (IndexNamed(from.Indexes, index.Name) == null) {
				changes.push(index.ToCreateIndexExpression(TableName, Schema));
			}
		}

		for (index in Indexes) {
			final was = IndexNamed(from.Indexes, index.Name);
			if (was != null && !index.Equals(was)) {
				changes.push(new DropIndexExpression(TableName, index.Name, Schema));
				changes.push(index.ToCreateIndexExpression(TableName, Schema));
			}
		}

		return changes;
	}

	/** The changes that turn `from` into `to`; the static form of `Diff`. */
	public static function DiffFrom(from:Null<DatabaseTableDefinition>, to:DatabaseTableDefinition):Array<SchemaChangeExpression> {
		return to.Diff(from);
	}

	/**
		Adds a column, or amends the one already there of that name — configuring a table starts
		from the table as it stands, it does not add a second column of the same name.
	**/
	public function Column(name:String, type:DatabaseColumnType, isNullable:Bool = true, isAutoIncrement:Bool = false,
			?maxLength:Int, ?precision:Int, ?scale:Int, ?defaultValue:String, ?collation:String, ?comment:String,
			?identity:IdentityKind):DatabaseTableDefinition {
		var column = FindColumn(name);
		if (column == null) {
			column = new DatabaseColumnDefinition(name);
			column.OrdinalIndex = Columns.length;
			Columns.push(column);
		}
		column.Type = type;
		column.IsNullable = isNullable;
		column.IsAutoIncrement = isAutoIncrement;
		column.Identity = identity == null ? ByDefault : identity;
		column.MaxLength = maxLength;
		column.Precision = precision;
		column.Scale = scale;
		column.DefaultValue = defaultValue;
		column.Collation = collation;
		column.Comment = comment;
		return this;
	}

	/** Marks a column as generated from `expression`, adding it if it is not already there. */
	public function SetGenerated(name:String, type:DatabaseColumnType, isNullable:Bool, expression:ISqlExpression,
			stored:Bool):DatabaseTableDefinition {
		var column = null;
		for (candidate in Columns) {
			if (candidate.Name == name) {
				column = candidate;
			}
		}
		if (column == null) {
			column = new DatabaseColumnDefinition(name, type, isNullable);
			column.OrdinalIndex = Columns.length;
			Columns.push(column);
		}
		column.SetGeneratedExpression(expression);
		column.GeneratedStored = stored;
		return this;
	}

	public function PrimaryKey(name:String, columns:Array<String>):DatabaseTableDefinition {
		Constraints.push(new DatabasePrimaryKeyConstraint(name, columns));
		return this;
	}

	public function ForeignKey(name:String, columns:Array<String>, referencedTable:String, referencedColumns:Array<String>,
			?onDelete:DatabaseForeignKeyAction, ?onUpdate:DatabaseForeignKeyAction, ?referencedSchema:String):DatabaseTableDefinition {
		Constraints.push(new DatabaseForeignKeyConstraint(name, columns, referencedTable, referencedColumns, onDelete,
			onUpdate, referencedSchema));
		return this;
	}

	public function Unique(name:String, columns:Array<String>):DatabaseTableDefinition {
		Constraints.push(new DatabaseUniqueConstraint(name, columns));
		return this;
	}

	public function Check(name:String, expression:String):DatabaseTableDefinition {
		Constraints.push(new DatabaseCheckConstraint(name, expression));
		return this;
	}

	/** An ascending index over the named columns. */
	public function Index(name:String, columns:Array<String>):DatabaseTableDefinition {
		return IndexColumns(name, columns.map(c -> new DatabaseIndexColumn(c)));
	}

	/** An index with its columns spelled out. */
	public function IndexColumns(name:String, columns:Array<DatabaseIndexColumn>, isUnique:Bool = false,
			isClustered:Bool = false, ?filterExpression:String, ?method:String):DatabaseTableDefinition {
		Indexes.push(new DatabaseIndexDefinition(name, columns, isUnique, isClustered, filterExpression, method));
		return this;
	}
}
