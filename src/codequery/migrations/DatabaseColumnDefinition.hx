package codequery.migrations;

import codequery.sqlexpressions.SqlType;

/** A column, as the schema describes it. */
class DatabaseColumnDefinition {
	public final Name:String;
	public final Type:SqlType;
	public final Nullable:Bool;

	/** Whether the database generates it, which is what a key usually is. */
	public final PrimaryKey:Bool;

	public function new(name:String, type:SqlType, nullable:Bool, primaryKey:Bool = false) {
		// A precision no database would take is refused here, naming the column, rather than by
		// the database naming nothing.
		switch type {
			case SqlDecimal(precision, scale) if (precision <= 0):
				throw 'Column $name: a decimal has at least one digit, not $precision';
			case SqlDecimal(precision, scale) if (scale > precision):
				throw 'Column $name: a decimal cannot keep more after the point ($scale) than it has digits ($precision)';
			case _:
		}
		this.Name = name;
		this.Type = type;
		this.Nullable = nullable;
		this.PrimaryKey = primaryKey;
	}

	/** Whether two describe the same column, which is what a diff turns on. */
	public function Matches(other:DatabaseColumnDefinition):Bool {
		return Name == other.Name
			&& Std.string(Type) == Std.string(other.Type)
			&& Nullable == other.Nullable
			&& PrimaryKey == other.PrimaryKey;
	}
}
