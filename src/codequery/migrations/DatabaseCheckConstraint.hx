package codequery.migrations;

import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.TableConstraint;

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
