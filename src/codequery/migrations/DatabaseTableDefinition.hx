package codequery.migrations;

import codequery.migrations.DatabaseColumnType;
import codequery.migrations.DatabaseTableConstraint;
import codequery.migrations.DatabaseIndexDefinition;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.SchemaChangeExpression;
import codequery.sqlexpressions.TableConstraint;
import codequery.sqlexpressions.TableCreateExpression;
import codequery.sqlexpressions.TablePartition;

/** A table, as the schema describes it. */
class DatabaseTableDefinition {
	public var Name:String;
	public var Schema:Null<String>;
	public var Columns:Array<DatabaseColumnDefinition>;
	public var Constraints:Array<DatabaseTableConstraint> = [];
	public var Indexes:Array<DatabaseIndexDefinition> = [];

	/** `CREATE TEMPORARY TABLE` — gone when the session is. */
	public final Temporary:Bool;

	/** `CREATE UNLOGGED TABLE` — not written to the log, so faster and not crash-safe. */
	public final Unlogged:Bool;

	/** How the table is partitioned, or null for an ordinary table. */
	public var Partition:Null<TablePartition> = null;

	public function new(name:String, ?columns:Array<DatabaseColumnDefinition>, ?schema:String,
			temporary:Bool = false, unlogged:Bool = false) {
		this.Name = name;
		this.Columns = columns == null ? [] : columns;
		this.Schema = schema;
		this.Temporary = temporary;
		this.Unlogged = unlogged;
	}

	/** The C# name for `Name`. */
	public var TableName(get, set):String;

	function get_TableName():String {
		return Name;
	}

	function set_TableName(value:String):String {
		return Name = value;
	}

	public function Column(name:String):Null<DatabaseColumnDefinition> {
		for (column in Columns) {
			if (column.Name == name) {
				return column;
			}
		}
		return null;
	}

	/** The column of that name, or null. Names compare regardless of case, as a database does. */
	public function FindColumn(name:String):Null<DatabaseColumnDefinition> {
		return Named(Columns, name);
	}

	// ---- the fluent surface -----------------------------------------------------------------------

	/**
		Adds a column — or amends the one already there, keeping its place: configuring a table starts
		from the table as it stands, it doesn't add a second column of the same name.
	**/
	public function AddColumn(name:String, type:DatabaseColumnType, isNullable:Bool = true, isAutoIncrement:Bool = false,
			?maxLength:Int, ?precision:Int, ?scale:Int, ?defaultValue:String, ?collation:String, ?comment:String,
			?identity:IdentityKind):DatabaseTableDefinition {
		var column:DatabaseColumnDefinition = null;
		for (held in Columns) {
			if (held.Name.toLowerCase() == name.toLowerCase()) {
				column = held;
			}
		}
		if (column == null) {
			column = DatabaseColumnDefinition.Of(name, type, isNullable);
			column.OrdinalIndex = Columns.length;
			Columns.push(column);
		}
		column.Type = type;
		column.Nullable = isNullable;
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
		var column = Column(name);
		if (column == null) {
			column = DatabaseColumnDefinition.Of(name, type, isNullable);
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
		Constraints.push(new DatabaseForeignKeyConstraint(name, columns, referencedTable, referencedColumns, onDelete, onUpdate,
			referencedSchema));
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
		return IndexOver(name, [for (c in columns) new DatabaseIndexColumn(c)]);
	}

	/** The C# name for `IndexOver`. */
	public function IndexColumns(name:String, columns:Array<DatabaseIndexColumn>, isUnique:Bool = false, isClustered:Bool = false,
			?filterExpression:String, ?method:String):DatabaseTableDefinition {
		return IndexOver(name, columns, isUnique, isClustered, filterExpression, method);
	}

	/** An index with its columns spelled out. */
	public function IndexOver(name:String, columns:Array<DatabaseIndexColumn>, isUnique:Bool = false, isClustered:Bool = false,
			?filterExpression:String, ?method:String):DatabaseTableDefinition {
		final index = new DatabaseIndexDefinition(name, columns);
		index.IsUnique = isUnique;
		index.IsClustered = isClustered;
		index.FilterExpression = filterExpression;
		index.Method = method;
		Indexes.push(index);
		return this;
	}

	// ---- to statements ----------------------------------------------------------------------------

	public function ToCreateTableExpression(ifNotExists:Bool = false):CreateTableExpression {
		final columns = [for (c in Columns) c.ToColumnDefinition()];
		final constraints = [for (c in Constraints) c.ToTableConstraint()];

		// A table that says which columns are its key but declares no constraint for it gets one.
		final keyed = [for (c in Columns) if (c.PrimaryKey) c.Name];
		var hasKey = false;
		for (c in Constraints) {
			if (c.ConstraintType() == DatabaseConstraintType.PrimaryKey) {
				hasKey = true;
			}
		}
		if (keyed.length > 0 && !hasKey) {
			constraints.unshift(new PrimaryKeyConstraint(keyed));
		}

		final made = new CreateTableExpression(Name, columns, constraints, Schema, ifNotExists, Partition);
		made.Temporary = Temporary;
		made.Unlogged = Unlogged;
		return made;
	}

	/** A CREATE TABLE on its own, for a driver to render — the C# `TableCreateExpression`. */
	public function ToTableCreateExpression(ifNotExists:Bool = false):TableCreateExpression {
		return new TableCreateExpression(Name, [for (c in Columns) c.ToColumnDefinition()],
			[for (c in Constraints) c.ToTableConstraint()], ifNotExists);
	}

	/** The changes that turn `from` into `to`; the static form of `Diff`. */
	public static function DiffFrom(from:Null<DatabaseTableDefinition>, to:DatabaseTableDefinition):Array<SchemaChangeExpression> {
		return to.Diff(from);
	}

	/** The changes that turn `from` into this table; a null `from` is a table to create. */
	public function Diff(from:Null<DatabaseTableDefinition>):Array<SchemaChangeExpression> {
		final changes:Array<SchemaChangeExpression> = [];

		if (from == null) {
			changes.push(ToCreateTableExpression());
			for (index in Indexes) {
				changes.push(index.ToCreateIndexExpression(Name, Schema));
			}
			return changes;
		}

		if (from.Name != Name) {
			changes.push(new RenameTableExpression(from.Name, Name, Schema));
		}

		// Columns.
		for (column in from.Columns) {
			if (Named(Columns, column.Name) == null) {
				changes.push(new DropColumnExpression(Name, column.Name, Schema));
			}
		}
		for (column in Columns) {
			if (Named(from.Columns, column.Name) == null) {
				changes.push(new AddColumnExpression(Name, column.ToColumnDefinition(), Schema));
			}
		}
		for (column in Columns) {
			final was = Named(from.Columns, column.Name);
			if (was == null || column.Matches(was)) {
				continue;
			}
			// A generated column cannot be altered in place: its whole declaration is re-emitted.
			if (column.GeneratedExpression != null || was.GeneratedExpression != null) {
				changes.push(new DropColumnExpression(Name, column.Name, Schema));
				changes.push(new AddColumnExpression(Name, column.ToColumnDefinition(), Schema));
			} else {
				changes.push(new AlterColumnExpression(Name, column.Name, column.ToColumnDefinition(), was.ToColumnDefinition(), Schema));
			}
		}

		// Constraints, by name.
		for (constraint in from.Constraints) {
			if (constraint.Name != null && ConstraintNamed(Constraints, constraint.Name) == null) {
				changes.push(new DropConstraintExpression(Name, constraint.Name, Schema));
			}
		}
		for (constraint in Constraints) {
			if (constraint.Name == null) {
				continue;
			}
			final was = ConstraintNamed(from.Constraints, constraint.Name);
			if (was == null) {
				changes.push(new AddConstraintExpression(Name, constraint.ToTableConstraint(), Schema));
			} else if (!constraint.Equals(was)) {
				changes.push(new DropConstraintExpression(Name, constraint.Name, Schema));
				changes.push(new AddConstraintExpression(Name, constraint.ToTableConstraint(), Schema));
			}
		}

		// Indexes, by name.
		for (index in from.Indexes) {
			if (IndexNamed(Indexes, index.Name) == null) {
				changes.push(new DropIndexExpression(Name, index.Name, Schema));
			}
		}
		for (index in Indexes) {
			final was = IndexNamed(from.Indexes, index.Name);
			if (was == null) {
				changes.push(index.ToCreateIndexExpression(Name, Schema));
			} else if (!index.Equals(was)) {
				changes.push(new DropIndexExpression(Name, index.Name, Schema));
				changes.push(index.ToCreateIndexExpression(Name, Schema));
			}
		}

		return changes;
	}

	public function Clone():DatabaseTableDefinition {
		final copy = new DatabaseTableDefinition(Name, [for (c in Columns) c.Clone()], Schema);
		copy.Constraints = [for (c in Constraints) c.Clone()];
		copy.Indexes = [for (i in Indexes) i.Clone()];
		copy.Partition = Partition;
		return copy;
	}

	static function Named(columns:Array<DatabaseColumnDefinition>, name:String):Null<DatabaseColumnDefinition> {
		for (column in columns) {
			if (column.Name.toLowerCase() == name.toLowerCase()) {
				return column;
			}
		}
		return null;
	}

	static function ConstraintNamed(constraints:Array<DatabaseTableConstraint>, name:String):Null<DatabaseTableConstraint> {
		for (constraint in constraints) {
			if (constraint.Name != null && constraint.Name.toLowerCase() == name.toLowerCase()) {
				return constraint;
			}
		}
		return null;
	}

	static function IndexNamed(indexes:Array<DatabaseIndexDefinition>, name:String):Null<DatabaseIndexDefinition> {
		for (index in indexes) {
			if (index.Name.toLowerCase() == name.toLowerCase()) {
				return index;
			}
		}
		return null;
	}
}
