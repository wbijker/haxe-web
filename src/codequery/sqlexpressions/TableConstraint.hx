package codequery.sqlexpressions;

/** A constraint as a CREATE TABLE says it. The C# classes of the same names. */
class TableConstraint {
	public final Name:Null<String>;

	/** Whether checking can be deferred to transaction commit. */
	public var Deferrable:Bool = false;

	/** When `Deferrable`, whether it defers by default. */
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

class ForeignKeyConstraint extends TableConstraint {
	public final Columns:Array<String>;
	public final ReferencedTable:String;
	public final ReferencedColumns:Array<String>;
	public final OnDelete:ForeignKeyAction;
	public final OnUpdate:ForeignKeyAction;

	public function new(columns:Array<String>, referencedTable:String, referencedColumns:Array<String>,
			onDelete:ForeignKeyAction = NoAction, onUpdate:ForeignKeyAction = NoAction, ?name:String) {
		super(name);
		this.Columns = columns;
		this.ReferencedTable = referencedTable;
		this.ReferencedColumns = referencedColumns;
		this.OnDelete = onDelete;
		this.OnUpdate = onUpdate;
	}
}

class UniqueConstraint extends TableConstraint {
	public final Columns:Array<String>;

	public function new(columns:Array<String>, ?name:String) {
		super(name);
		this.Columns = columns;
	}
}

class CheckConstraint extends TableConstraint {
	public final Condition:ISqlExpression;

	public function new(condition:ISqlExpression, ?name:String) {
		super(name);
		this.Condition = condition;
	}
}

enum ForeignKeyAction {
	NoAction;
	Cascade;
	SetNull;
	SetDefault;
	Restrict;
}
