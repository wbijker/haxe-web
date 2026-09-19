package codequery.migrations;

import codequery.ValueGeneration;
import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.TableConstraint;

/** A constraint, as the schema describes it — serializable, and compared by value in a diff. */
class DatabaseTableConstraint {
	public var Name:Null<String>;

	public var ConstraintType(get, never):DatabaseConstraintType;

	function new(?name:String) {
		this.Name = name;
	}

	function get_ConstraintType():DatabaseConstraintType {
		throw "A constraint says which kind it is";
	}

	/** The same constraint as a CREATE TABLE says it. */
	public function ToTableConstraint():TableConstraint {
		throw "A constraint says how it is created";
	}

	/** Whether two describe the same constraint, which is what a diff turns on. */
	public function Equals(other:DatabaseTableConstraint):Bool {
		return false;
	}

	static function SameList(a:Array<String>, b:Array<String>):Bool {
		if (a.length != b.length) {
			return false;
		}
		for (index in 0...a.length) {
			if (a[index] != b[index]) {
				return false;
			}
		}
		return true;
	}
}
