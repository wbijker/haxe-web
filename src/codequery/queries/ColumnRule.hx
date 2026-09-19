package codequery.queries;

import codequery.sqlexpressions.SqlType;

/** One column worth checking before a row is sent, and the member it reads. */
class ColumnRule {
	public final Member:String;
	public final Column:String;
	public final Type:SqlType;
	public final Nullable:Bool;

	public function new(member:String, column:String, type:SqlType, nullable:Bool) {
		this.Member = member;
		this.Column = column;
		this.Type = type;
		this.Nullable = nullable;
	}

	/** Whether the column constrains anything a value can fail. */
	public function Limits():Bool {
		return !Nullable || switch Type {
			case SqlVarChar(_) | SqlDecimal(_, _): true;
			case _: false;
		}
	}
}
