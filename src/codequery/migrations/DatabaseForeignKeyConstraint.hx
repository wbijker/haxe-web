package codequery.migrations;

import codequery.sqlexpressions.TableConstraint;

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
