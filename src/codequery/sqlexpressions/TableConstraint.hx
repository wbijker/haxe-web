package codequery.sqlexpressions;

/** What a foreign key does when the row it points at goes. */
enum ForeignKeyAction {
	NoAction;
	Cascade;
	SetNull;
	SetDefault;
	Restrict;
}

/** A constraint as CREATE TABLE or ADD CONSTRAINT states it. */
class TableConstraint {
	public final Name:Null<String>;

	/** Whether checking can be deferred to commit (`DEFERRABLE`). */
	public var Deferrable:Bool = false;

	/** When `Deferrable`, whether it defers by default (`INITIALLY DEFERRED`). */
	public var InitiallyDeferred:Bool = false;

	function new(?name:String) {
		this.Name = name;
	}
}

class PrimaryKeyConstraint extends TableConstraint {
	public final Columns:Array<String>;

	public function new(columns:Array<String>, ?name:String) {
		super(name);
		this.Columns = columns;
	}
}

class UniqueConstraint extends TableConstraint {
	public final Columns:Array<String>;

	public function new(columns:Array<String>, ?name:String) {
		super(name);
		this.Columns = columns;
	}
}

class ForeignKeyConstraint extends TableConstraint {
	public final Columns:Array<String>;
	public final ReferencedTable:String;
	public final ReferencedColumns:Array<String>;
	public final OnDelete:ForeignKeyAction;
	public final OnUpdate:ForeignKeyAction;

	public function new(columns:Array<String>, referencedTable:String, referencedColumns:Array<String>,
			?onDelete:ForeignKeyAction, ?onUpdate:ForeignKeyAction, ?name:String) {
		super(name);
		this.Columns = columns;
		this.ReferencedTable = referencedTable;
		this.ReferencedColumns = referencedColumns;
		this.OnDelete = onDelete == null ? NoAction : onDelete;
		this.OnUpdate = onUpdate == null ? NoAction : onUpdate;
	}

	/** The single-column form of the C# constructor. */
	public static function Of(column:String, referencedTable:String, referencedColumn:String,
			?onDelete:ForeignKeyAction, ?onUpdate:ForeignKeyAction, ?name:String):ForeignKeyConstraint {
		return new ForeignKeyConstraint([column], referencedTable, [referencedColumn], onDelete, onUpdate, name);
	}
}

class CheckConstraint extends TableConstraint {
	public final Condition:ISqlExpression;

	public function new(condition:ISqlExpression, ?name:String) {
		super(name);
		this.Condition = condition;
	}
}
