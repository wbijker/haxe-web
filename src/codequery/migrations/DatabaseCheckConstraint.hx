package codequery.migrations;

import codequery.ValueGeneration;
import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.TableConstraint;

class DatabaseCheckConstraint extends DatabaseTableConstraint {
	/** The condition as SQL text, emitted verbatim into the DDL. */
	public var Expression:String;

	public function new(?name:String, expression:String = "") {
		super(name);
		this.Expression = expression;
	}

	override function get_ConstraintType():DatabaseConstraintType {
		return Check;
	}

	override public function ToTableConstraint():TableConstraint {
		return new CheckConstraint(new RawSqlExpression(Expression), Name);
	}

	override public function Equals(other:DatabaseTableConstraint):Bool {
		final ck = Std.downcast(other, DatabaseCheckConstraint);
		return ck != null && Name == ck.Name && Expression == ck.Expression;
	}
}
