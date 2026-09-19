package codequery.migrations;

import codequery.ValueGeneration;
import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.TableConstraint;

class DatabasePrimaryKeyConstraint extends DatabaseTableConstraint {
	public var Columns:Array<String>;

	/** Whether the key is produced by the database or supplied by the application. */
	public var Generation:ValueGeneration = ServerGenerated;

	public function new(?name:String, ?columns:Array<String>, ?generation:ValueGeneration) {
		super(name);
		this.Columns = columns == null ? [] : columns;
		if (generation != null) {
			this.Generation = generation;
		}
	}

	override function get_ConstraintType():DatabaseConstraintType {
		return PrimaryKey;
	}

	override public function ToTableConstraint():TableConstraint {
		return new PrimaryKeyConstraint(Columns, Name);
	}

	override public function Equals(other:DatabaseTableConstraint):Bool {
		final pk = Std.downcast(other, DatabasePrimaryKeyConstraint);
		return pk != null && Name == pk.Name && DatabaseTableConstraint.SameList(Columns, pk.Columns) && Generation == pk.Generation;
	}
}
