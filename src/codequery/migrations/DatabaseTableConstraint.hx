package codequery.migrations;

import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.TableConstraint;

enum DatabaseConstraintType {
	PrimaryKey;
	ForeignKey;
	Unique;
	Check;
	Default;
}

enum DatabaseForeignKeyAction {
	NoAction;
	Cascade;
	SetNull;
	SetDefault;
	Restrict;
}

/** Whether a key is produced by the database or supplied by the application. */
enum ValueGeneration {
	ServerGenerated;
	ClientGenerated;
}

/** A constraint as the schema records it; each kind knows the statement form it becomes. */
class DatabaseTableConstraint {
	public var Name:Null<String>;

	function new(?name:String) {
		this.Name = name;
	}

	public function ConstraintType():DatabaseConstraintType {
		throw "abstract";
	}

	public function ToTableConstraint():TableConstraint {
		throw "abstract";
	}

	public function Equals(other:DatabaseTableConstraint):Bool {
		throw "abstract";
	}

	public function Clone():DatabaseTableConstraint {
		throw "abstract";
	}

	static function SameList(a:Array<String>, b:Array<String>):Bool {
		return a.length == b.length && a.join("\n") == b.join("\n");
	}
}

class DatabasePrimaryKeyConstraint extends DatabaseTableConstraint {
	public var Columns:Array<String>;
	public var Generation:ValueGeneration = ServerGenerated;

	public function new(?name:String, ?columns:Array<String>) {
		super(name);
		this.Columns = columns == null ? [] : columns;
	}

	override public function ConstraintType():DatabaseConstraintType {
		return PrimaryKey;
	}

	override public function ToTableConstraint():TableConstraint {
		return new PrimaryKeyConstraint(Columns.copy(), Name);
	}

	override public function Equals(other:DatabaseTableConstraint):Bool {
		final pk = Std.downcast(other, DatabasePrimaryKeyConstraint);
		return pk != null && Name == pk.Name && DatabaseTableConstraint.SameList(Columns, pk.Columns)
			&& Std.string(Generation) == Std.string(pk.Generation);
	}

	override public function Clone():DatabaseTableConstraint {
		final copy = new DatabasePrimaryKeyConstraint(Name, Columns.copy());
		copy.Generation = Generation;
		return copy;
	}
}

class DatabaseForeignKeyConstraint extends DatabaseTableConstraint {
	public var Columns:Array<String>;
	public var ReferencedTable:String;
	public var ReferencedSchema:Null<String> = null;
	public var ReferencedColumns:Array<String>;
	public var OnDelete:DatabaseForeignKeyAction = NoAction;
	public var OnUpdate:DatabaseForeignKeyAction = NoAction;

	public function new(?name:String, ?columns:Array<String>, referencedTable:String = "", ?referencedColumns:Array<String>,
			?onDelete:DatabaseForeignKeyAction, ?onUpdate:DatabaseForeignKeyAction, ?referencedSchema:String) {
		super(name);
		this.Columns = columns == null ? [] : columns;
		this.ReferencedTable = referencedTable;
		this.ReferencedColumns = referencedColumns == null ? [] : referencedColumns;
		this.OnDelete = onDelete == null ? NoAction : onDelete;
		this.OnUpdate = onUpdate == null ? NoAction : onUpdate;
		this.ReferencedSchema = referencedSchema;
	}

	override public function ConstraintType():DatabaseConstraintType {
		return ForeignKey;
	}

	override public function ToTableConstraint():TableConstraint {
		return new ForeignKeyConstraint(Columns.copy(), ReferencedTable, ReferencedColumns.copy(), Action(OnDelete),
			Action(OnUpdate), Name);
	}

	public static function Action(action:DatabaseForeignKeyAction):ForeignKeyAction {
		return switch action {
			case NoAction: NoAction;
			case Cascade: Cascade;
			case SetNull: SetNull;
			case SetDefault: SetDefault;
			case Restrict: Restrict;
		}
	}

	override public function Equals(other:DatabaseTableConstraint):Bool {
		final fk = Std.downcast(other, DatabaseForeignKeyConstraint);
		return fk != null
			&& Name == fk.Name
			&& DatabaseTableConstraint.SameList(Columns, fk.Columns)
			&& ReferencedTable == fk.ReferencedTable
			&& ReferencedSchema == fk.ReferencedSchema
			&& DatabaseTableConstraint.SameList(ReferencedColumns, fk.ReferencedColumns)
			&& Std.string(OnDelete) == Std.string(fk.OnDelete)
			&& Std.string(OnUpdate) == Std.string(fk.OnUpdate);
	}

	override public function Clone():DatabaseTableConstraint {
		return new DatabaseForeignKeyConstraint(Name, Columns.copy(), ReferencedTable, ReferencedColumns.copy(), OnDelete,
			OnUpdate, ReferencedSchema);
	}
}

class DatabaseUniqueConstraint extends DatabaseTableConstraint {
	public var Columns:Array<String>;

	public function new(?name:String, ?columns:Array<String>) {
		super(name);
		this.Columns = columns == null ? [] : columns;
	}

	override public function ConstraintType():DatabaseConstraintType {
		return Unique;
	}

	override public function ToTableConstraint():TableConstraint {
		return new UniqueConstraint(Columns.copy(), Name);
	}

	override public function Equals(other:DatabaseTableConstraint):Bool {
		final unique = Std.downcast(other, DatabaseUniqueConstraint);
		return unique != null && Name == unique.Name && DatabaseTableConstraint.SameList(Columns, unique.Columns);
	}

	override public function Clone():DatabaseTableConstraint {
		return new DatabaseUniqueConstraint(Name, Columns.copy());
	}
}

class DatabaseCheckConstraint extends DatabaseTableConstraint {
	/** The condition as SQL text: what is written into the DDL, and what a git diff reads. */
	public var Expression:String;

	public function new(?name:String, expression:String = "") {
		super(name);
		this.Expression = expression;
	}

	override public function ConstraintType():DatabaseConstraintType {
		return Check;
	}

	override public function ToTableConstraint():TableConstraint {
		return new CheckConstraint(new RawSqlExpression(Expression), Name);
	}

	override public function Equals(other:DatabaseTableConstraint):Bool {
		final check = Std.downcast(other, DatabaseCheckConstraint);
		return check != null && Name == check.Name && Expression == check.Expression;
	}

	override public function Clone():DatabaseTableConstraint {
		return new DatabaseCheckConstraint(Name, Expression);
	}
}
