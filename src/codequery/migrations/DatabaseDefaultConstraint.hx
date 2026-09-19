package codequery.migrations;

import codequery.ValueGeneration;
import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.TableConstraint;

class DatabaseDefaultConstraint extends DatabaseTableConstraint {
	public var ColumnName:String;
	public var Expression:String;

	public function new(?name:String, columnName:String = "", expression:String = "") {
		super(name);
		this.ColumnName = columnName;
		this.Expression = expression;
	}

	override function get_ConstraintType():DatabaseConstraintType {
		return Default;
	}

	override public function ToTableConstraint():TableConstraint {
		throw "Default constraints are applied at column level";
	}

	override public function Equals(other:DatabaseTableConstraint):Bool {
		final def = Std.downcast(other, DatabaseDefaultConstraint);
		return def != null && Name == def.Name && ColumnName == def.ColumnName && Expression == def.Expression;
	}
}
