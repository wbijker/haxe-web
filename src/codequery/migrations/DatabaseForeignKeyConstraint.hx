package codequery.migrations;

import codequery.ValueGeneration;
import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.TableConstraint;

class DatabaseForeignKeyConstraint extends DatabaseTableConstraint {
	public var Columns:Array<String>;
	public var ReferencedTable:String;
	public var ReferencedSchema:Null<String>;
	public var ReferencedColumns:Array<String>;
	public var OnDelete:DatabaseForeignKeyAction = NoAction;
	public var OnUpdate:DatabaseForeignKeyAction = NoAction;

	public function new(?name:String, ?columns:Array<String>, referencedTable:String = "", ?referencedColumns:Array<String>,
			?onDelete:DatabaseForeignKeyAction, ?onUpdate:DatabaseForeignKeyAction, ?referencedSchema:String) {
		super(name);
		this.Columns = columns == null ? [] : columns;
		this.ReferencedTable = referencedTable;
		this.ReferencedColumns = referencedColumns == null ? [] : referencedColumns;
		if (onDelete != null) {
			this.OnDelete = onDelete;
		}
		if (onUpdate != null) {
			this.OnUpdate = onUpdate;
		}
		this.ReferencedSchema = referencedSchema;
	}

	override function get_ConstraintType():DatabaseConstraintType {
		return ForeignKey;
	}

	override public function ToTableConstraint():TableConstraint {
		return new ForeignKeyConstraint(Columns, ReferencedTable, ReferencedColumns, Action(OnDelete), Action(OnUpdate), Name);
	}

	/** The same action, as the CREATE TABLE names it. */
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
			&& OnDelete == fk.OnDelete
			&& OnUpdate == fk.OnUpdate;
	}
}
