package codequery.migrations;

import codequery.migrations.DatabaseIndexDefinition;
import codequery.migrations.DatabaseTableConstraint;
import codequery.migrations.DbTablePartition;
import codequery.migrations.EntityTableBuilder;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.SqlType;
#if macro
import codequery.migrations.CheckExpressionRenderer;
import codequery.migrations.ColumnBuilderMacros;
import codequery.migrations.SchemaMembers;
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.TypeTools;
#end

/**
	Configures one column of a table, and everything that hangs off that one column — its SQL type
	and facets, and the single-column constraints. Obtained from `EntityTableBuilder.Column`:

	```haxe
	schema.DefineTable(Author, "authors")
		.Column(a -> a.id).AutoIncrement()
		.Column(a -> a.name).MaxLength(255).NotNull();
	```

	The C# `ColumnBuilderBase<TEntity, TProperty, TSelf>` and its `ColumnBuilder`. C# hands a typed
	builder per property type — `StringColumnBuilder`, `DecimalColumnBuilder` — each offering only
	what its type can be told; here every one of those is a subclass of this, and the typed surface
	lives here so a chain keeps it after `NotNull()`, whichever builder began it.
**/
class ColumnBuilder<TEntity, TProperty> {
	public final Table:EntityTableBuilder<TEntity>;
	public var ColumnName(default, null):String;

	// What the column is made as, where naming it is what adds it.
	final type:DatabaseColumnType;
	final sqlType:Null<SqlType>;
	final nullable:Bool;
	final isGuid:Bool;

	/** The entity's class name, where the builder was reached from a property of it; names a refusal. */
	final entityName:Null<String>;

	public function new(table:EntityTableBuilder<TEntity>, name:String, type:DatabaseColumnType, nullable:Bool, isGuid:Bool = false,
			?sqlType:SqlType, ?entityName:String) {
		this.Table = table;
		this.ColumnName = name;
		this.type = type;
		this.sqlType = sqlType;
		this.nullable = nullable;
		this.isGuid = isGuid || sqlType == SqlGuid;
		this.entityName = entityName;
		// Naming a column puts it in the table, in the order it was named.
		Definition;
	}

	/** The column as it stands — added from its field's type where the table has none yet. */
	public var Definition(get, never):DatabaseColumnDefinition;

	function get_Definition():DatabaseColumnDefinition {
		final held = Table.Definition.FindColumn(ColumnName);
		if (held != null) {
			return held;
		}
		final column = sqlType != null
			? new DatabaseColumnDefinition(ColumnName, sqlType, nullable)
			: DatabaseColumnDefinition.Of(ColumnName, type, nullable);
		column.OrdinalIndex = Table.Definition.Columns.length;
		Table.Definition.Columns.push(column);
		return column;
	}

	// ---- continuing the chain ----------------------------------------------------------------------

	/** On to the next column. */
	public macro function Column(self:Expr, property:Expr):Expr {
		return ColumnBuilderMacros.ColumnCall(macro $self.Table, property);
	}

	/** This column and another, for an index or a key over both. */
	public macro function And(self:Expr, property:Expr):Expr {
		final read = EntityTableBuilder.Read(macro $self.Table, property);
		return macro $self.Columns().AndNamed($v{read.name}, ${read.type}, $v{read.nullable});
	}

	/** This column as a group of one, to add to. */
	public function Columns():ColumnsBuilder<TEntity> {
		Definition;
		return new ColumnsBuilder<TEntity>(Table, [new DatabaseIndexColumn(ColumnName)]);
	}

	/** The column sorted descending, in an index over it and what follows. */
	public function Descending():ColumnsBuilder<TEntity> {
		return Columns().Descending();
	}

	// ---- naming and facets -------------------------------------------------------------------------

	/** Renames the column in the database, leaving the property alone. */
	public function Named(name:String):ColumnBuilder<TEntity, TProperty> {
		Definition.Name = name;
		ColumnName = name;
		return this;
	}

	/** Sets the SQL type (and its size) explicitly — the escape hatch when no typed method fits. */
	public function As(type:DatabaseColumnType, ?maxLength:Int, ?precision:Int, ?scale:Int):ColumnBuilder<TEntity, TProperty> {
		final column = Definition;
		column.Type = type;
		if (maxLength != null) column.MaxLength = maxLength;
		if (precision != null) column.Precision = precision;
		if (scale != null) column.Scale = scale;
		return this;
	}

	public function Null():ColumnBuilder<TEntity, TProperty> {
		return Nullable(true);
	}

	public function NotNull():ColumnBuilder<TEntity, TProperty> {
		return Nullable(false);
	}

	public function Nullable(isNullable:Bool = true):ColumnBuilder<TEntity, TProperty> {
		Definition.Nullable = isNullable;
		return this;
	}

	/**
		The column's DEFAULT, written as the value it is: `Default(() -> 0)`, `Default(() -> Sql.now())`
		— C#'s `Default(Expression<Func<TProperty>>)`, which takes no parameter since a default cannot
		read the row it is defaulting. A plain value is taken too: `Default(new Date(1990, 0, 1))`.
	**/
	public macro function Default(self:Expr, value:Expr):Expr {
		return switch value.expr {
			case EFunction(_, f) if (f.args.length == 0):
				final tree = codequery.sqlexpressions.ExpressionConverter.ConvertKey(value, []);
				macro $self.DefaultTree($tree);
			case _:
				macro $self.DefaultValue($value);
		}
	}

	/** What `Default` expands to for a lambda. */
	public function DefaultTree(tree:ISqlExpression):ColumnBuilder<TEntity, TProperty> {
		Definition.SetDefaultValue(tree);
		// Said here, the default is no longer the property initializer's.
		Definition.DeclaredDefault = null;
		return this;
	}

	/**
		What `Default` expands to for a plain value: a number, a string, a boolean, a date. A date is
		the value it constructs, since nothing in a default can name a column.
	**/
	public function DefaultValue(value:Dynamic):ColumnBuilder<TEntity, TProperty> {
		final column = Definition;
		// `Date` here is the column builder's own method, so the class is named in full.
		if (Std.isOfType(value, std.Date)) {
			final date:std.Date = value;
			final text = date.getHours() == 0 && date.getMinutes() == 0 && date.getSeconds() == 0
				? DateTools.format(date, "%Y-%m-%d")
				: DateTools.format(date, "%Y-%m-%d %H:%M:%S");
			column.SetDefaultValue(new ConstSqlExpression(SqlConstString(text)));
		} else if (value == null) {
			column.DefaultValue = null;
			column.DefaultValueTree = null;
		} else {
			final constant = ConstantOf(value);
			column.SetDefaultValue(constant != null ? constant : new ConstSqlExpression(SqlConstString(Std.string(value))));
		}
		column.DeclaredDefault = null;
		return this;
	}

	/** A plain value as a constant, or null for a value that is not one. */
	public static function ConstantOf(value:Dynamic):Null<ISqlExpression> {
		if (value == null) {
			return null;
		}
		if (Std.isOfType(value, Bool)) return new ConstSqlExpression(SqlConstBool(value));
		if (Std.isOfType(value, Int)) return new ConstSqlExpression(SqlConstInt(value));
		if (Std.isOfType(value, Float)) return new ConstSqlExpression(SqlConstFloat(value));
		if (Std.isOfType(value, String)) return new ConstSqlExpression(SqlConstString(value));
		return null;
	}

	public function Collate(collation:String):ColumnBuilder<TEntity, TProperty> {
		Definition.Collation = collation;
		return this;
	}

	public function Comment(comment:String):ColumnBuilder<TEntity, TProperty> {
		Definition.Comment = comment;
		return this;
	}

	/** Whether the database assigns the value on insert. */
	public function AutoIncrement(autoIncrement:Bool = true):ColumnBuilder<TEntity, TProperty> {
		Definition.IsAutoIncrement = autoIncrement;
		return this;
	}

	/** The database assigns the value on insert, in the form `identity` names. */
	public function Identity(?identity:IdentityKind):ColumnBuilder<TEntity, TProperty> {
		Definition.IsAutoIncrement = true;
		Definition.Identity = identity == null ? ByDefault : identity;
		return this;
	}

	// ---- constraints on this column ----------------------------------------------------------------

	/**
		The table's primary key, on this column, replacing any key already inferred. Only a
		server-generated key may auto-increment, and a server-generated Guid is filled by a database
		UUID default instead. The C# order: generation, autoIncrement, name, identity.
	**/
	public function PrimaryKey(?generation:ValueGeneration, autoIncrement:Bool = true, ?name:String,
			?identity:IdentityKind):ColumnBuilder<TEntity, TProperty> {
		final table = Table.Definition;
		final kept = generation == null ? ServerGenerated : generation;
		final autoIncrements = kept == ServerGenerated && autoIncrement && !isGuid;

		table.Constraints = [for (c in table.Constraints) if (!Std.isOfType(c, DatabasePrimaryKeyConstraint)) c];
		final key = new DatabasePrimaryKeyConstraint(name == null ? 'PK_${table.Name}' : name, [ColumnName]);
		key.Generation = kept;
		table.Constraints.push(key);

		final column = Definition;
		column.PrimaryKey = true;
		column.IsAutoIncrement = autoIncrements;
		column.Identity = identity == null ? ByDefault : identity;
		column.ServerGeneratedGuid = kept == ServerGenerated && isGuid;
		column.Nullable = false;
		return this;
	}

	public function Unique(?name:String):ColumnBuilder<TEntity, TProperty> {
		Definition;
		Table.Definition.Unique(name == null ? 'UQ_${Table.Definition.Name}_$ColumnName' : name, [ColumnName]);
		return this;
	}

	/** An index on this column. */
	public function Index(?name:String, descending:Bool = false):ColumnBuilder<TEntity, TProperty> {
		return AddIndex(name, false, descending, BTree);
	}

	/** An index on this column, stored the way `type` says — a JSON column searched by its parts wants Gin. */
	public function IndexUsing(type:IndexType, ?name:String, descending:Bool = false):ColumnBuilder<TEntity, TProperty> {
		return AddIndex(name, false, descending, type);
	}

	public function UniqueIndex(?name:String, descending:Bool = false):ColumnBuilder<TEntity, TProperty> {
		return AddIndex(name, true, descending, BTree);
	}

	function AddIndex(name:Null<String>, isUnique:Bool, descending:Bool, type:IndexType):ColumnBuilder<TEntity, TProperty> {
		Definition;
		final table = Table.Definition;
		table.IndexOver(name == null ? 'IX_${table.Name}_$ColumnName' : name,
			[new DatabaseIndexColumn(ColumnName, descending ? DatabaseSortOrder.Descending : DatabaseSortOrder.Ascending)], isUnique, false, null,
			IndexTypes.Method(type));
		return this;
	}

	/**
		A CHECK over this column's value — the lambda's parameter is the column: `Check(r -> r >= 1)`
		renders `CHECK (rating >= 1)`. Written SQL is taken as it stands: `Check("rating >= 1")`.
	**/
	public macro function Check(self:Expr, expression:Expr, ?name:Expr):Expr {
		final held = ColumnBuilderMacros.Or(name);
		return switch expression.expr {
			case EFunction(_, _):
				final render = CheckExpressionRenderer.RenderColumn(expression, expression.pos);
				macro $self.CheckWith($render, $held);
			case _:
				macro $self.CheckSql($expression, $held);
		}
	}

	/** What `Check` expands to for a lambda: the check, written for whatever the column is called by then. */
	public function CheckWith(render:String->String, ?name:String):ColumnBuilder<TEntity, TProperty> {
		return CheckSql(render(ColumnName), name);
	}

	/** What `Check` expands to for SQL. */
	public function CheckSql(expression:String, ?name:String):ColumnBuilder<TEntity, TProperty> {
		Definition;
		Table.Definition.Check(name == null ? 'CK_${Table.Definition.Name}_$ColumnName' : name, expression);
		return this;
	}

	/**
		A foreign key from this column to a column of another entity's table:
		`ForeignKey(Author, a -> a.id)` — C#'s `ForeignKey<Author>(a => a.Id, …)` — or, by name,
		`ForeignKey("authors", "id")`.
	**/
	public macro function ForeignKey(self:Expr, referenced:Expr, referencedColumn:Expr, ?onDelete:Expr, ?onUpdate:Expr,
			?name:Expr, ?referencedTable:Expr, ?referencedSchema:Expr):Expr {
		final rest = [onDelete, onUpdate, name, referencedTable, referencedSchema].map(ColumnBuilderMacros.Or);
		final target = if (ColumnBuilderMacros.IsString(referenced)) {
			[referenced, referencedColumn];
		} else {
			final row = SchemaMembers.ClassTypeOf(referenced);
			final column = ColumnBuilderMacros.ColumnNameOf(row, referencedColumn);
			final table = codequery.inspection.SchemaInspector.TableNameOf(row);
			[macro $v{table}, macro $v{column}];
		}
		return {expr: ECall(macro $self.ForeignKeyTo, target.concat(rest)), pos: self.pos};
	}

	/** What `ForeignKey` expands to. */
	public function ForeignKeyTo(referencedEntityTable:String, referencedColumn:String, ?onDelete:DatabaseForeignKeyAction,
			?onUpdate:DatabaseForeignKeyAction, ?name:String, ?referencedTable:String, ?referencedSchema:String):ColumnBuilder<TEntity, TProperty> {
		Definition;
		Table.Definition.ForeignKey(name == null ? 'FK_${Table.Definition.Name}_$ColumnName' : name, [ColumnName],
			referencedTable == null ? referencedEntityTable : referencedTable, [referencedColumn], onDelete, onUpdate, referencedSchema);
		return this;
	}

	/** Partitions the table by this column: `Column(t -> t.entryDate).PartitionBy().AsRange().Add(...)`. */
	public function PartitionBy():PartitionKeyBuilder {
		Definition;
		return new PartitionKeyBuilder(ColumnName).Into(Table.Definition);
	}

	// ---- computed and converted --------------------------------------------------------------------

	/** Makes this a generated column from an expression over the entity: `Generated(b -> b.price / b.pages)`. */
	public macro function Generated(self:Expr, expression:Expr, ?stored:Expr):Expr {
		final row = switch Context.typeof(macro $self.Table).follow() {
			case TInst(_, [e]): e;
			case _: Context.error("Not a table builder", self.pos);
		}
		final tree = codequery.sqlexpressions.ExpressionConverter.ConvertKey(expression, [row]);
		final persisted = stored == null || stored.expr.match(EConst(CIdent("null"))) ? macro true : stored;
		return macro $self.GeneratedTree($tree, $persisted);
	}

	/** What `Generated` expands to. */
	public function GeneratedTree(tree:ISqlExpression, stored:Bool = true):ColumnBuilder<TEntity, TProperty> {
		final column = Definition;
		Table.Definition.SetGenerated(ColumnName, column.Type, column.Nullable, tree, stored);
		return this;
	}

	/**
		Stores this column as another type, converting on the way in and out. The column's stored
		type becomes the provider type; a default read from the entity is converted with it.
	**/
	public macro function Convert(self:Expr, toProvider:Expr, fromProvider:Expr):Expr {
		final providerType = ColumnBuilderMacros.ProviderTypeOf(toProvider);
		return macro $self.ConvertTo($providerType, $toProvider);
	}

	/** What `Convert` expands to. */
	public function ConvertTo(providerType:DatabaseColumnType, toProvider:Dynamic->Dynamic):ColumnBuilder<TEntity, TProperty> {
		final column = Definition;
		column.Type = providerType;
		column.MaxLength = null;

		// A default read from the entity is in the entity's terms, and the column is about to stop being in them.
		if (column.DeclaredDefault != null) {
			final declared = column.DeclaredDefault;
			column.DefaultValue = null;
			column.DefaultValueTree = null;
			column.DeclaredDefault = null;
			final converted = ConstantOf(toProvider(declared));
			if (converted != null) {
				column.SetDefaultValue(converted);
			}
		}
		return this;
	}

	// ---- the typed surface -------------------------------------------------------------------------
	// C# offers each of these only on the builder whose type it applies to; here they are on every
	// builder, and what each means follows the column's type.

	/** A width: `VARCHAR(n)` for text, `VARBINARY(n)` for bytes. */
	public function MaxLength(length:Int):ColumnBuilder<TEntity, TProperty> {
		if (IsBinary()) {
			return As(DatabaseColumnType.VarBinary, length);
		}
		if (IsTextual()) {
			return As(IsUnicode() ? DatabaseColumnType.NVarChar : DatabaseColumnType.VarChar, length);
		}
		Definition.MaxLength = length;
		return this;
	}

	/** A fixed width: `CHAR(n)` for text, `BINARY(n)` for bytes. */
	public function Fixed(length:Int):ColumnBuilder<TEntity, TProperty> {
		return IsBinary()
			? As(DatabaseColumnType.Binary, length)
			: As(IsUnicode() ? DatabaseColumnType.NChar : DatabaseColumnType.Char, length);
	}

	/** Unbounded text. */
	public function Text():ColumnBuilder<TEntity, TProperty> {
		Definition.MaxLength = null;
		return As(IsUnicode() ? DatabaseColumnType.NText : DatabaseColumnType.Text);
	}

	/** National (Unicode) text, whichever text type the column is. */
	public function Unicode(unicode:Bool = true):ColumnBuilder<TEntity, TProperty> {
		final column = Definition;
		column.Type = switch [unicode, column.Type] {
			case [true, DatabaseColumnType.VarChar]: DatabaseColumnType.NVarChar;
			case [true, DatabaseColumnType.Char]: DatabaseColumnType.NChar;
			case [true, DatabaseColumnType.Text]: DatabaseColumnType.NText;
			case [false, DatabaseColumnType.NVarChar]: DatabaseColumnType.VarChar;
			case [false, DatabaseColumnType.NChar]: DatabaseColumnType.Char;
			case [false, DatabaseColumnType.NText]: DatabaseColumnType.Text;
			case [_, other]: other;
		}
		return this;
	}

	public function Json():ColumnBuilder<TEntity, TProperty> {
		return As(DatabaseColumnType.Json);
	}

	public function Xml():ColumnBuilder<TEntity, TProperty> {
		return As(DatabaseColumnType.Xml);
	}

	public function Blob():ColumnBuilder<TEntity, TProperty> {
		return As(DatabaseColumnType.Blob);
	}

	/** How exact a decimal column is, checked against the schema's own rule. */
	public function Precision(precision:Int, scale:Int = 0):ColumnBuilder<TEntity, TProperty> {
		As(DatabaseColumnType.Decimal);
		GuardPrecision(precision, scale, '${entityName == null ? Table.Definition.Name : entityName}.${Definition.Name}');
		Definition.Precision = precision;
		Definition.Scale = scale;
		return this;
	}

	/** Refuses a precision no database would take, naming what declared it. */
	public static function GuardPrecision(precision:Int, scale:Int, declaredBy:String):Void {
		if (precision < 1) {
			throw '$declaredBy asks for a decimal of $precision digits. A column keeps at least one.';
		}
		if (scale < 0) {
			throw '$declaredBy asks for $scale digits after the point. A column keeps none or more.';
		}
		if (scale > precision) {
			throw '$declaredBy asks for $scale digits after the point out of $precision in total. A decimal cannot keep more after the point than it keeps altogether.';
		}
	}

	public function Date():ColumnBuilder<TEntity, TProperty> {
		return As(DatabaseColumnType.Date);
	}

	public function DateTime():ColumnBuilder<TEntity, TProperty> {
		return As(DatabaseColumnType.DateTime);
	}

	public function Timestamp():ColumnBuilder<TEntity, TProperty> {
		return As(DatabaseColumnType.Timestamp);
	}

	public function Time():ColumnBuilder<TEntity, TProperty> {
		return As(DatabaseColumnType.Time);
	}

	function IsBinary():Bool {
		return switch Definition.Type {
			case DatabaseColumnType.Binary | DatabaseColumnType.VarBinary | DatabaseColumnType.Blob: true;
			case _: false;
		}
	}

	function IsTextual():Bool {
		return switch Definition.Type {
			case DatabaseColumnType.VarChar | DatabaseColumnType.Char | DatabaseColumnType.Text
				| DatabaseColumnType.NVarChar | DatabaseColumnType.NChar | DatabaseColumnType.NText: true;
			case _: false;
		}
	}

	function IsUnicode():Bool {
		return switch Definition.Type {
			case DatabaseColumnType.NVarChar | DatabaseColumnType.NChar | DatabaseColumnType.NText: true;
			case _: false;
		}
	}
}
