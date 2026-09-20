package codequery.sqlexpressions;

/** Which form a generated key takes — what the database does with a row that carries a key of its own. */
enum IdentityKind {
	ByDefault;
	Always;
	Serial;
}

/** A column as a CREATE TABLE or ADD COLUMN states it: the C# `ColumnDefinition`. */
class ColumnDefinition {
	public final Name:String;
	public final Type:SqlType;
	public final IsNullable:Bool;
	public final DefaultValue:Null<ISqlExpression>;
	public final MaxLength:Null<Int>;
	public final Precision:Null<Int>;
	public final Scale:Null<Int>;

	/** Whether the column is a server-generated identity. */
	public final IsAutoIncrement:Bool;

	/** Which identity form the column takes; meaningless where `IsAutoIncrement` is false. */
	public final Identity:IdentityKind;

	/** The column collation name (rendered as `COLLATE …`), or null for the default. */
	public final Collation:Null<String>;

	/**
		What this column references, when its foreign key has been lifted out of the CREATE TABLE and
		added afterwards — rendered as a comment beside the column in a pretty-printed statement.
	**/
	public var ReferencesNote:Null<String> = null;

	/** The generated column's expression in its stable string form, or null for an ordinary column. */
	public var GeneratedExpression:Null<String> = null;

	/** The generated expression as a tree, for a driver to render in its own spelling. */
	public var GeneratedExpressionTree:Null<ISqlExpression> = null;

	/** Whether a generated column is stored rather than computed on read. */
	public var GeneratedStored:Null<Bool> = null;

	/** Whether a Guid key is filled in by the database. */
	public var ServerGeneratedGuid:Bool = false;

	public function new(name:String, type:SqlType, isNullable:Bool = true, ?defaultValue:ISqlExpression,
			?maxLength:Int, ?precision:Int, ?scale:Int, isAutoIncrement:Bool = false, ?collation:String,
			?identity:IdentityKind) {
		this.Name = name;
		this.Type = type;
		this.IsNullable = isNullable;
		this.DefaultValue = defaultValue;
		this.MaxLength = maxLength;
		this.Precision = precision;
		this.Scale = scale;
		this.IsAutoIncrement = isAutoIncrement;
		this.Collation = collation;
		this.Identity = identity == null ? ByDefault : identity;
	}
}
