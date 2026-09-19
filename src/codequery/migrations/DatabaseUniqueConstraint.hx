package codequery.migrations;

import codequery.ValueGeneration;
import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.TableConstraint;

class DatabaseUniqueConstraint extends DatabaseTableConstraint {
	public var Columns:Array<String>;

	public function new(?name:String, ?columns:Array<String>) {
		super(name);
		this.Columns = columns == null ? [] : columns;
	}

	override function get_ConstraintType():DatabaseConstraintType {
		return Unique;
	}

	override public function ToTableConstraint():TableConstraint {
		return new UniqueConstraint(Columns, Name);
	}

	override public function Equals(other:DatabaseTableConstraint):Bool {
		final uq = Std.downcast(other, DatabaseUniqueConstraint);
		return uq != null && Name == uq.Name && DatabaseTableConstraint.SameList(Columns, uq.Columns);
	}
}
