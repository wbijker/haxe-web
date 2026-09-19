package codequery.migrations;

import codequery.IdentityKind;
import codequery.ValueGeneration;
import codequery.migrations.DatabaseIndexDefinition;
import codequery.migrations.DatabaseTableConstraint;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.ISqlExpression;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;

using haxe.macro.TypeTools;
#end

/**
	Configures one column of a table, and everything that hangs off that one column — its SQL type
	and facets, and the single-column constraints. Obtained from `EntityTableBuilder.Column`.

	Every method hands back `TSelf`, the concrete builder, so a chain never widens to the base and
	loses what the column's own type offers — which is what C#'s `TSelf` parameter does too.
**/
class ColumnBuilderBase<TEntity, TProperty, TSelf> {
	final table:EntityTableBuilder<TEntity>;
	final definition:DatabaseTableDefinition;

	// What the column is made as, where naming it is what adds it.
	final prototypeType:DatabaseColumnType;
	final prototypeNullable:Bool;
	final isGuid:Bool;

	/** The column's name in the database. */
	public var ColumnName(default, null):String;

	/** The table this column belongs to — to carry on with something table-wide. */
	public var Table(get, never):EntityTableBuilder<TEntity>;

	function new(table:EntityTableBuilder<TEntity>, definition:DatabaseTableDefinition, columnName:String,
			type:DatabaseColumnType, nullable:Bool, isGuid:Bool = false) {
		this.table = table;
		this.definition = definition;
		this.ColumnName = columnName;
		this.prototypeType = type;
		this.prototypeNullable = nullable;
		this.isGuid = isGuid;
		// Naming a column is enough to declare it.
		final _ = Definition;
	}

	function get_Table():EntityTableBuilder<TEntity> {
		return table;
	}

	function Self():TSelf {
		return cast this;
	}

	/**
		The column as it currently stands — inspected from the entity, amended by everything here.
		Added if the property maps to no column yet.
	**/
	public var Definition(get, never):DatabaseColumnDefinition;

	function get_Definition():DatabaseColumnDefinition {
		var column = definition.FindColumn(ColumnName);
		if (column == null) {
			column = new DatabaseColumnDefinition(ColumnName, prototypeType, prototypeNullable);
			column.OrdinalIndex = definition.Columns.length;
			definition.Columns.push(column);
		}
		return column;
	}

	// --- Naming and facets ------------------------------------------------------------------------

	/** Renames the column in the database, leaving the property alone. */
	public function Named(name:String):TSelf {
		Definition.Name = name;
		ColumnName = name;
		return Self();
	}

	/** Sets the SQL type (and its size) explicitly — the escape hatch when no typed method fits. */
	public function As(type:DatabaseColumnType, ?maxLength:Int, ?precision:Int, ?scale:Int):TSelf {
		final column = Definition;
		column.Type = type;
		if (maxLength != null) column.MaxLength = maxLength;
		if (precision != null) column.Precision = precision;
		if (scale != null) column.Scale = scale;
		return Self();
	}

	public function Null():TSelf {
		return Nullable(true);
	}

	public function NotNull():TSelf {
		return Nullable(false);
	}

	public function Nullable(isNullable:Bool = true):TSelf {
		Definition.IsNullable = isNullable;
		return Self();
	}

	/**
		The column's DEFAULT, written as the value it is: `Default(() -> 0)`, `Default(() -> Sql.now())`.
		It takes no parameter, since a default cannot read the row it is defaulting.
	**/
	public macro function Default(self:Expr, value:Expr):Expr {
		final tree = codequery.sqlexpressions.ExpressionConverter.ConvertKey(value, []);
		return macro $self.DefaultTree($tree);
	}

	/** What `Default` expands to. */
	public function DefaultTree(tree:ISqlExpression):TSelf {
		Definition.SetDefaultValue(tree);
		// Said here, the default is no longer the property initializer's.
		Definition.DeclaredDefault = null;
		return Self();
	}

	public function Collate(collation:String):TSelf {
		Definition.Collation = collation;
		return Self();
	}

	public function Comment(comment:String):TSelf {
		Definition.Comment = comment;
		return Self();
	}

	public function AutoIncrement(autoIncrement:Bool = true):TSelf {
		Definition.IsAutoIncrement = autoIncrement;
		return Self();
	}

	/** The database assigns the value on insert, in the form `identity` names. */
	public function Identity(identity:IdentityKind = ByDefault):TSelf {
		Definition.IsAutoIncrement = true;
		Definition.Identity = identity;
		return Self();
	}

	// --- Constraints on this column ---------------------------------------------------------------

	/**
		The table's primary key, on this column. Only a server-generated key may auto-increment, and a
		server-generated Guid is filled by a database UUID default instead. Replaces any key inferred.
	**/
	public function PrimaryKey(generation:ValueGeneration = ServerGenerated, autoIncrement:Bool = true, ?name:String,
			identity:IdentityKind = ByDefault):TSelf {
		final autoIncrements = generation == ServerGenerated && autoIncrement && !isGuid;

		definition.Constraints = definition.Constraints.filter(c -> !Std.isOfType(c, DatabasePrimaryKeyConstraint));
		definition.Constraints.push(new DatabasePrimaryKeyConstraint(name == null ? 'PK_${definition.TableName}' : name,
			[ColumnName], generation));

		final column = Definition;
		column.IsAutoIncrement = autoIncrements;
		column.Identity = identity;
		column.ServerGeneratedGuid = generation == ServerGenerated && isGuid;
		return Self();
	}

	public function Unique(?name:String):TSelf {
		definition.Unique(name == null ? 'UQ_${definition.TableName}_$ColumnName' : name, [ColumnName]);
		return Self();
	}

	public function Index(?name:String, descending:Bool = false):TSelf {
		return AddIndex(name, false, descending, null);
	}

	/** An index stored the way `method` says — `gin` for a JSON column searched by its parts. */
	public function IndexUsing(method:String, ?name:String, descending:Bool = false):TSelf {
		return AddIndex(name, false, descending, method);
	}

	public function UniqueIndex(?name:String, descending:Bool = false):TSelf {
		return AddIndex(name, true, descending, null);
	}

	function AddIndex(name:Null<String>, isUnique:Bool, descending:Bool, method:Null<String>):TSelf {
		final column = new DatabaseIndexColumn(ColumnName, descending ? DatabaseSortOrder.Descending : DatabaseSortOrder.Ascending);
		definition.IndexColumns(name == null ? 'IX_${definition.TableName}_$ColumnName' : name, [column], isUnique, false, null, method);
		return Self();
	}

	/**
		A CHECK over this column's value — the lambda's parameter is the column: `Check(r -> r >= 1)`
		renders `CHECK (rating >= 1)`.
	**/
	public macro function Check(self:Expr, expression:Expr, ?name:Expr):Expr {
		final render = CheckExpressionRenderer.RenderColumn(expression, expression.pos);
		return macro $self.CheckWith($render, $name);
	}

	/** What `Check` expands to: the check, written for whatever the column is called by then. */
	public function CheckWith(render:String->String, ?name:String):TSelf {
		definition.Check(name == null ? 'CK_${definition.TableName}_$ColumnName' : name, render(ColumnName));
		return Self();
	}

	/**
		A foreign key from this column to a column of another entity's table:
		`ForeignKey(Author, a -> a.id)`. C#'s `ForeignKey<Author>(a => a.Id, …)`.
	**/
	public macro function ForeignKey(self:Expr, referenced:Expr, referencedColumn:Expr, ?onDelete:Expr, ?onUpdate:Expr,
			?name:Expr, ?referencedTable:Expr, ?referencedSchema:Expr):Expr {
		final row = SchemaMembers.ClassTypeOf(referenced);
		final column = ColumnBuilderMacros.ColumnNameOf(row, referencedColumn);
		final table = codequery.inspection.SchemaInspector.TableNameOf(row);
		return macro $self.ForeignKeyTo($v{table}, $v{column}, $onDelete, $onUpdate, $name, $referencedTable, $referencedSchema);
	}

	/** What `ForeignKey` expands to. */
	public function ForeignKeyTo(referencedEntityTable:String, referencedColumn:String, ?onDelete:DatabaseForeignKeyAction,
			?onUpdate:DatabaseForeignKeyAction, ?name:String, ?referencedTable:String, ?referencedSchema:String):TSelf {
		definition.ForeignKey(name == null ? 'FK_${definition.TableName}_$ColumnName' : name, [ColumnName],
			referencedTable == null ? referencedEntityTable : referencedTable, [referencedColumn], onDelete, onUpdate,
			referencedSchema);
		return Self();
	}

	// --- Computed and converted -------------------------------------------------------------------

	/** Makes this a generated column from an expression over the entity: `Generated(b -> b.price / b.pages)`. */
	public macro function Generated(self:Expr, expression:Expr, ?stored:Expr):Expr {
		final entity = ColumnBuilderMacros.EntityOf(macro $self.Table);
		final row = switch haxe.macro.Context.typeof(macro $self.Table).follow() {
			case TInst(_, [e]): e;
			case _: haxe.macro.Context.error("Not a table builder", self.pos);
		}
		final tree = codequery.sqlexpressions.ExpressionConverter.ConvertKey(expression, [row]);
		final persisted = stored == null || stored.expr.match(EConst(CIdent("null"))) ? macro true : stored;
		return macro $self.GeneratedTree($tree, $persisted);
	}

	/** What `Generated` expands to. */
	public function GeneratedTree(tree:ISqlExpression, stored:Bool = true):TSelf {
		definition.SetGenerated(ColumnName, prototypeType, prototypeNullable, tree, stored);
		return Self();
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
	public function ConvertTo(providerType:DatabaseColumnType, toProvider:Dynamic->Dynamic):TSelf {
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
		return Self();
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

	// --- Continuing the chain ---------------------------------------------------------------------

	/** Takes this column together with another, for a constraint that spans them. */
	public macro function And(self:Expr, property:Expr):Expr {
		final entity = ColumnBuilderMacros.EntityOf(macro $self.Table);
		final column = ColumnBuilderMacros.ColumnNameOf(entity, property);
		return macro {
			$self.Table.Column($property);
			$self.AndNamed($v{column});
		};
	}

	/** What `And` expands to. */
	public function AndNamed(column:String):ColumnGroupBuilder<TEntity> {
		return new ColumnGroupBuilder<TEntity>(table, definition, ColumnName).AndNamed(column);
	}

	/** Sorts this column descending in the composite index that follows. */
	public function Descending():ColumnGroupBuilder<TEntity> {
		return new ColumnGroupBuilder<TEntity>(table, definition, ColumnName).Descending();
	}

	/** Starts configuring another column, so one chain can cover several. */
	public macro function Column(self:Expr, property:Expr):Expr {
		return ColumnBuilderMacros.ColumnCall(macro $self.Table, property);
	}

	// --- The typed surface ------------------------------------------------------------------------
	// Offered on every builder, so a chain keeps them after NotNull(); what each means follows the
	// column's type, as C#'s typed builders do by offering them only where they apply.

	/** A width: `VARCHAR(n)` for text, `VARBINARY(n)` for bytes. */
	public function MaxLength(length:Int):TSelf {
		return IsBinary() ? As(DatabaseColumnType.VarBinary, length) : As(IsUnicode() ? DatabaseColumnType.NVarChar : DatabaseColumnType.VarChar, length);
	}

	/** A fixed width: `CHAR(n)` for text, `BINARY(n)` for bytes. */
	public function Fixed(length:Int):TSelf {
		return IsBinary() ? As(DatabaseColumnType.Binary, length) : As(IsUnicode() ? DatabaseColumnType.NChar : DatabaseColumnType.Char, length);
	}

	/** Unbounded text. */
	public function Text():TSelf {
		Definition.MaxLength = null;
		return As(IsUnicode() ? DatabaseColumnType.NText : DatabaseColumnType.Text);
	}

	/** National (Unicode) text, whichever text type the column is. */
	public function Unicode(unicode:Bool = true):TSelf {
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
		return Self();
	}

	public function Json():TSelf {
		return As(DatabaseColumnType.Json);
	}

	public function Xml():TSelf {
		return As(DatabaseColumnType.Xml);
	}

	public function Blob():TSelf {
		return As(DatabaseColumnType.Blob);
	}

	/** How exact a decimal column is, checked against the schema's own rule. */
	public function Precision(precision:Int, scale:Int = 0):TSelf {
		As(DatabaseColumnType.Decimal);
		GuardPrecision(precision, scale, '${definition.TableName}.${Definition.Name}');
		Definition.Precision = precision;
		Definition.Scale = scale;
		return Self();
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

	public function Date():TSelf {
		return As(DatabaseColumnType.Date);
	}

	public function DateTime():TSelf {
		return As(DatabaseColumnType.DateTime);
	}

	public function Timestamp():TSelf {
		return As(DatabaseColumnType.Timestamp);
	}

	public function Time():TSelf {
		return As(DatabaseColumnType.Time);
	}

	function IsBinary():Bool {
		return switch Definition.Type {
			case DatabaseColumnType.Binary | DatabaseColumnType.VarBinary | DatabaseColumnType.Blob: true;
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
