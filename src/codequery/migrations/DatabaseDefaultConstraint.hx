package codequery.migrations;

import codequery.migrations.DatabaseTableConstraint;
import codequery.sqlexpressions.TableConstraint;

/** A DEFAULT recorded as a constraint of its own, as a snapshot read from some databases carries it. */
class DatabaseDefaultConstraint extends DatabaseTableConstraint {
	public var ColumnName:String;
	public var Expression:String;

	public function new(?name:String, columnName:String = "", expression:String = "") {
		super(name);
		this.ColumnName = columnName;
		this.Expression = expression;
	}

	override public function ConstraintType():DatabaseConstraintType {
		return Default;
	}

	override public function ToTableConstraint():TableConstraint {
		throw "Default constraints are applied at column level";
	}

	override public function Equals(other:DatabaseTableConstraint):Bool {
		final def = Std.downcast(other, DatabaseDefaultConstraint);
		return def != null && Name == def.Name && ColumnName == def.ColumnName && Expression == def.Expression;
	}

	override public function Clone():DatabaseTableConstraint {
		return new DatabaseDefaultConstraint(Name, ColumnName, Expression);
	}
}
