package codequery.migrations;

import codequery.sqlexpressions.TableConstraint;

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
