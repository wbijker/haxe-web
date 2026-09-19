package codequery.migrations;

import codequery.migrations.DatabaseColumnType;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.RawSqlExpression;
import codequery.sqlexpressions.SqlType;

/**
	A column, as the schema describes it: the C# `DatabaseColumnDefinition`.

	Built from a SQL type, which is what the entities say, and recorded as a column type with the
	length or precision beside it, which is what a snapshot says.
**/
class DatabaseColumnDefinition {
	public var Name:String;
	public var Type:DatabaseColumnType;
	public var Nullable:Bool;

	/** Whether the database generates it, which is what a key usually is. */
	public var PrimaryKey:Bool;

	public var IsAutoIncrement:Bool = false;
	public var Identity:IdentityKind = ByDefault;

	/** The column's DEFAULT in a stable, provider-neutral string form; what the snapshot stores. */
	public var DefaultValue:Null<String> = null;

	/** The default as an expression tree, present when the column came from code. */
	public var DefaultValueTree:Null<ISqlExpression> = null;

	public var MaxLength:Null<Int> = null;
	public var Precision:Null<Int> = null;
	public var Scale:Null<Int> = null;
	public var Collation:Null<String> = null;
	public var Comment:Null<String> = null;

	/**
		The column's place among the others, captured when the table was read. Excluded from
		`Matches` so a pure reorder is not a change; what tells a rename from a drop and an add.
	**/
	public var OrdinalIndex:Null<Int> = null;

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
		final recorded = DatabaseColumnTypes.OfSqlType(type);
		this.Type = recorded.type;
		this.MaxLength = recorded.maxLength;
		this.Precision = recorded.precision;
		this.Scale = recorded.scale;
		this.Nullable = nullable;
		this.PrimaryKey = primaryKey;
	}

	/** The C# object-initializer form: a column by its recorded type. */
	public static function Of(name:String, type:DatabaseColumnType, nullable:Bool = true):DatabaseColumnDefinition {
		final column = new DatabaseColumnDefinition(name, SqlUnknown, nullable);
		column.Type = type;
		return column;
	}

	public var IsNullable(get, set):Bool;

	function get_IsNullable():Bool {
		return Nullable;
	}

	function set_IsNullable(value:Bool):Bool {
		return Nullable = value;
	}

	/** The SQL type a statement over this column carries. */
	public function SqlType():SqlType {
		return DatabaseColumnTypes.ToSqlType(Type, MaxLength, Precision, Scale);
	}

	/** Sets the default from its tree, deriving the stored string form. */
	public function SetDefaultValue(tree:ISqlExpression):Void {
		DefaultValueTree = tree;
		DefaultValue = new codequery.sqldrivers.SqlTranslator().RenderExpression(tree);
	}

	/** The column as a CREATE TABLE states it. */
	public function ToColumnDefinition():ColumnDefinition {
		// The tree where there is one; a snapshot-loaded column has only the string, which is SQL
		// already and goes through as it stands.
		final defaultExpression:Null<ISqlExpression> = DefaultValueTree != null
			? DefaultValueTree
			: (DefaultValue != null ? new RawSqlExpression(DefaultValue) : null);

		return new ColumnDefinition(Name, SqlType(), Nullable, defaultExpression, MaxLength, Precision, Scale,
			IsAutoIncrement, Collation, Identity);
	}

	/** A copy, so a canonical ordering never disturbs the live schema. */
	public function Clone():DatabaseColumnDefinition {
		final copy = new DatabaseColumnDefinition(Name, SqlUnknown, Nullable, PrimaryKey);
		copy.Type = Type;
		copy.IsAutoIncrement = IsAutoIncrement;
		copy.Identity = Identity;
		copy.DefaultValue = DefaultValue;
		copy.DefaultValueTree = DefaultValueTree;
		copy.MaxLength = MaxLength;
		copy.Precision = Precision;
		copy.Scale = Scale;
		copy.Collation = Collation;
		copy.Comment = Comment;
		copy.OrdinalIndex = OrdinalIndex;
		return copy;
	}

	/** Whether two describe the same column, which is what a diff turns on. */
	public function Matches(other:DatabaseColumnDefinition):Bool {
		return Name == other.Name
			&& Std.string(Type) == Std.string(other.Type)
			&& Nullable == other.Nullable
			&& IsAutoIncrement == other.IsAutoIncrement
			&& Std.string(Identity) == Std.string(other.Identity)
			&& DefaultValue == other.DefaultValue
			&& MaxLength == other.MaxLength
			&& Precision == other.Precision
			&& Scale == other.Scale
			&& Collation == other.Collation;
	}

	/** The C# `Equals`. */
	public function Equals(other:DatabaseColumnDefinition):Bool {
		return other != null && Matches(other);
	}
}
