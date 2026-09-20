package codequery.migrations;

import codequery.sqlexpressions.TableConstraint;

/** Whether a key is produced by the database or supplied by the application — C#'s `CodeQuery.ValueGeneration`. */
typedef ValueGeneration = codequery.ValueGeneration;

/** A constraint as the schema records it; each kind knows the statement form it becomes. */
class DatabaseTableConstraint {
	public var Name:Null<String>;

	function new(?name:String) {
		this.Name = name;
	}

	public function ConstraintType():DatabaseConstraintType {
		throw "abstract";
	}

	public function ToTableConstraint():TableConstraint {
		throw "abstract";
	}

	public function Equals(other:DatabaseTableConstraint):Bool {
		throw "abstract";
	}

	public function Clone():DatabaseTableConstraint {
		throw "abstract";
	}

	static function SameList(a:Array<String>, b:Array<String>):Bool {
		return a.length == b.length && a.join("\n") == b.join("\n");
	}
}
