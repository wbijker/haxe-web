package codequery.migrations;

import codequery.sqlexpressions.TableConstraint;

class DatabasePrimaryKeyConstraint extends DatabaseTableConstraint {
	public var Columns:Array<String>;
	public var Generation:ValueGeneration = ServerGenerated;

	public function new(?name:String, ?columns:Array<String>, ?generation:ValueGeneration) {
		super(name);
		this.Columns = columns == null ? [] : columns;
		if (generation != null) {
			this.Generation = generation;
		}
	}

	override public function ConstraintType():DatabaseConstraintType {
		return PrimaryKey;
	}

	override public function ToTableConstraint():TableConstraint {
		return new PrimaryKeyConstraint(Columns.copy(), Name);
	}

	override public function Equals(other:DatabaseTableConstraint):Bool {
		final pk = Std.downcast(other, DatabasePrimaryKeyConstraint);
		return pk != null && Name == pk.Name && DatabaseTableConstraint.SameList(Columns, pk.Columns)
			&& Std.string(Generation) == Std.string(pk.Generation);
	}

	override public function Clone():DatabaseTableConstraint {
		final copy = new DatabasePrimaryKeyConstraint(Name, Columns.copy());
		copy.Generation = Generation;
		return copy;
	}
}
