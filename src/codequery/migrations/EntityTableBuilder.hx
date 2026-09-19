package codequery.migrations;

import codequery.migrations.DatabaseIndexDefinition;
import codequery.migrations.DatabaseTableConstraint;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.ConstSqlExpression;
import codequery.sqlexpressions.SqlType;
#if macro
import codequery.sqlexpressions.ColumnsBuilder as EntityColumns;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
#end

/** How an index stores what it indexes. */
enum IndexType {
	BTree;
	Gin;
	Gist;
	Brin;
	Hash;
}

class IndexTypes {
	/** The `USING` method, or null for the default B-tree, which goes unsaid. */
	public static function Method(type:IndexType):Null<String> {
		return switch type {
			case BTree: null;
			case Gin: "gin";
			case Gist: "gist";
			case Brin: "brin";
			case Hash: "hash";
		}
	}
}

/**
	Configures an entity's table, column by column, naming each by a lambda over the entity —
	the C# `EntityTableBuilder<TEntity>`:

	```haxe
	schema.DefineTable(Author, "authors")
		.Column(a -> a.id).AutoIncrement()
		.Column(a -> a.name).MaxLength(255).NotNull();
	```
**/
class EntityTableBuilder<T> {
	public final Definition:DatabaseTableDefinition;
	public final Snapshot:Null<SchemaSnapshot>;

	public function new(definition:DatabaseTableDefinition, ?snapshot:SchemaSnapshot) {
		this.Definition = definition;
		this.Snapshot = snapshot;
	}

	/** Configures the column `property` maps to: `t.Column(a -> a.name)`. */
	public macro function Column(self:Expr, property:Expr):Expr {
		final read = EntityTableBuilder.Read(self, property);
		return macro $self.ColumnNamed($v{read.name}, ${read.type}, $v{read.nullable});
	}

	/** The column by name, made from its type where the table has none yet. */
	public function ColumnNamed(name:String, type:SqlType, nullable:Bool):ColumnBuilder<T> {
		return new ColumnBuilder<T>(this, name, type, nullable);
	}

	/** A CHECK over the table, as SQL. */
	public function Check(name:String, expression:String):EntityTableBuilder<T> {
		Definition.Check(name, expression);
		return this;
	}

	/** Seeds the table with fixed records; compared by primary key and field by field on later migrations. */
	public function HasData(records:Array<T>):EntityTableBuilder<T> {
		if (Snapshot == null) {
			throw "HasData requires an entity bound to a schema; obtain the builder from schema.Entity(T).";
		}
		Snapshot.SeedRows(Definition.Name, cast records);
		return this;
	}

	#if macro
	/** The field a lambda's body names, under whatever the parser wrapped it in. */
	static function FieldOf(e:Expr):String {
		return switch e.expr {
			case EField(_, name): name;
			case EReturn(inner) | EMeta(_, inner) | EParenthesis(inner): FieldOf(inner);
			case EBlock([inner]): FieldOf(inner);
			case _: Context.error("Expected a property accessor, e.g. x -> x.property", e.pos);
		}
	}

	/** The column a lambda over the entity names, with what the entity says of it. */
	public static function Read(self:Expr, property:Expr):{name:String, type:Expr, nullable:Bool} {
		final entity = switch Context.typeof(self).follow() {
			case TInst(_, [row]): row;
			case t: Context.error('${t.toString()} is not a table builder', self.pos);
		}
		final row = switch entity.follow() {
			case TInst(t, _): t.get();
			case t: Context.error('${t.toString()} is not an entity class', property.pos);
		}
		final fieldName = switch property.expr {
			case EFunction(_, f) if (f.expr != null): FieldOf(f.expr);
			case _: Context.error("Expected a property accessor, e.g. x -> x.property", property.pos);
		}
		for (field in row.fields.get()) {
			if (field.name == fieldName) {
				return {
					name: EntityColumns.ColumnNameOf(field),
					type: EntityColumns.SqlTypeOfField(field),
					nullable: SchemaInspector.IsNullable(field)
				};
			}
		}
		return Context.error('${row.name} has no field $fieldName', property.pos);
	}
	#end
}

/** One column of an entity's table, configured. */
class ColumnBuilder<T> {
	public final Table:EntityTableBuilder<T>;
	public var ColumnName(default, null):String;
	final type:SqlType;
	final nullable:Bool;

	public function new(table:EntityTableBuilder<T>, name:String, type:SqlType, nullable:Bool) {
		this.Table = table;
		this.ColumnName = name;
		this.type = type;
		this.nullable = nullable;
		// Naming a column puts it in the table, in the order it was named.
		Definition;
	}

	/** The column as it stands — added from its field's type where the table has none yet. */
	public var Definition(get, never):DatabaseColumnDefinition;

	function get_Definition():DatabaseColumnDefinition {
		final held = Table.Definition.Column(ColumnName);
		if (held != null) {
			return held;
		}
		final column = new DatabaseColumnDefinition(ColumnName, type, nullable);
		column.OrdinalIndex = Table.Definition.Columns.length;
		Table.Definition.Columns.push(column);
		return column;
	}

	/** On to the next column. */
	public macro function Column(self:Expr, property:Expr):Expr {
		return macro $self.Table.Column($property);
	}

	/** This column and another, for an index or a key over both. */
	public macro function And(self:Expr, property:Expr):Expr {
		final read = EntityTableBuilder.Read(macro $self.Table, property);
		return macro $self.Columns().AndNamed($v{read.name}, ${read.type}, $v{read.nullable});
	}

	/** This column as a group of one, to add to. */
	public function Columns():ColumnsBuilder<T> {
		Definition;
		return new ColumnsBuilder<T>(Table, [new DatabaseIndexColumn(ColumnName)]);
	}

	/** The column sorted descending, in an index over it and what follows. */
	public function Descending():ColumnsBuilder<T> {
		return Columns().Descending();
	}

	public function Named(name:String):ColumnBuilder<T> {
		Definition.Name = name;
		ColumnName = name;
		return this;
	}

	public function Null():ColumnBuilder<T> {
		return Nullable(true);
	}

	public function NotNull():ColumnBuilder<T> {
		return Nullable(false);
	}

	public function Nullable(isNullable:Bool = true):ColumnBuilder<T> {
		Definition.Nullable = isNullable;
		return this;
	}

	public function MaxLength(length:Int):ColumnBuilder<T> {
		Definition.MaxLength = length;
		return this;
	}

	public function Precision(precision:Int, scale:Int):ColumnBuilder<T> {
		Definition.Precision = precision;
		Definition.Scale = scale;
		return this;
	}

	/**
		The column's DEFAULT, written as the value it is: a number, a string, a boolean, a date. A
		date is the value it constructs, since nothing in a default can name a column.
	**/
	public function Default(value:Dynamic):ColumnBuilder<T> {
		final column = Definition;
		if (Std.isOfType(value, Date)) {
			final date:Date = value;
			final text = date.getHours() == 0 && date.getMinutes() == 0 && date.getSeconds() == 0
				? DateTools.format(date, "%Y-%m-%d")
				: DateTools.format(date, "%Y-%m-%d %H:%M:%S");
			column.SetDefaultValue(new ConstSqlExpression(SqlConstString(text)));
		} else if (Std.isOfType(value, Bool)) {
			column.SetDefaultValue(new ConstSqlExpression(SqlConstBool(value)));
		} else if (Std.isOfType(value, Int)) {
			column.SetDefaultValue(new ConstSqlExpression(SqlConstInt(value)));
		} else if (Std.isOfType(value, Float)) {
			column.SetDefaultValue(new ConstSqlExpression(SqlConstFloat(value)));
		} else if (value == null) {
			column.DefaultValue = null;
			column.DefaultValueTree = null;
		} else {
			column.SetDefaultValue(new ConstSqlExpression(SqlConstString(Std.string(value))));
		}
		return this;
	}

	public function Collate(collation:String):ColumnBuilder<T> {
		Definition.Collation = collation;
		return this;
	}

	public function Comment(comment:String):ColumnBuilder<T> {
		Definition.Comment = comment;
		return this;
	}

	/** Whether the database assigns the value on insert. */
	public function AutoIncrement(autoIncrement:Bool = true):ColumnBuilder<T> {
		Definition.IsAutoIncrement = autoIncrement;
		return this;
	}

	/** The database assigns the value on insert, in the form `identity` names. */
	public function Identity(?identity:IdentityKind):ColumnBuilder<T> {
		Definition.IsAutoIncrement = true;
		Definition.Identity = identity == null ? ByDefault : identity;
		return this;
	}

	/**
		The table's primary key, on this column, replacing any key already inferred. A server-generated
		key may auto-increment; a client-generated one never does.
	**/
	public function PrimaryKey(?name:String, autoIncrement:Bool = true, ?identity:IdentityKind, ?generation:ValueGeneration):ColumnBuilder<T> {
		final table = Table.Definition;
		final kept = generation == null ? ServerGenerated : generation;
		table.Constraints = [for (c in table.Constraints) if (!Std.isOfType(c, DatabasePrimaryKeyConstraint)) c];
		final key = new DatabasePrimaryKeyConstraint(name == null ? 'PK_${table.Name}' : name, [ColumnName]);
		key.Generation = kept;
		table.Constraints.push(key);

		final column = Definition;
		column.PrimaryKey = true;
		column.IsAutoIncrement = kept == ServerGenerated && autoIncrement;
		column.Identity = identity == null ? ByDefault : identity;
		column.Nullable = false;
		return this;
	}

	public function Unique(?name:String):ColumnBuilder<T> {
		Definition;
		Table.Definition.Unique(name == null ? 'UQ_${Table.Definition.Name}_$ColumnName' : name, [ColumnName]);
		return this;
	}

	/** An index on this column. */
	public function Index(?name:String, descending:Bool = false):ColumnBuilder<T> {
		return AddIndex(name, false, descending, BTree);
	}

	/** An index on this column, stored the way `type` says — a JSON column searched by its parts wants Gin. */
	public function IndexUsing(type:IndexType, ?name:String, descending:Bool = false):ColumnBuilder<T> {
		return AddIndex(name, false, descending, type);
	}

	public function UniqueIndex(?name:String, descending:Bool = false):ColumnBuilder<T> {
		return AddIndex(name, true, descending, BTree);
	}

	function AddIndex(name:Null<String>, isUnique:Bool, descending:Bool, type:IndexType):ColumnBuilder<T> {
		Definition;
		final table = Table.Definition;
		table.IndexOver(name == null ? 'IX_${table.Name}_$ColumnName' : name,
			[new DatabaseIndexColumn(ColumnName, descending ? DatabaseSortOrder.Descending : DatabaseSortOrder.Ascending)], isUnique, false, null, IndexTypes.Method(type));
		return this;
	}

	/** A CHECK over this column's value, as SQL. */
	public function Check(expression:String, ?name:String):ColumnBuilder<T> {
		Definition;
		Table.Definition.Check(name == null ? 'CK_${Table.Definition.Name}_$ColumnName' : name, expression);
		return this;
	}

	/** A foreign key from this column to another table's key. */
	public function ForeignKey(referencedTable:String, referencedColumn:String, ?onDelete:DatabaseForeignKeyAction,
			?onUpdate:DatabaseForeignKeyAction, ?name:String):ColumnBuilder<T> {
		Definition;
		Table.Definition.ForeignKey(name == null ? 'FK_${Table.Definition.Name}_$ColumnName' : name, [ColumnName], referencedTable,
			[referencedColumn], onDelete, onUpdate);
		return this;
	}
}

/** Several columns named together, for an index or a key over all of them. */
class ColumnsBuilder<T> {
	public final Table:EntityTableBuilder<T>;
	final columns:Array<DatabaseIndexColumn>;

	public function new(table:EntityTableBuilder<T>, columns:Array<DatabaseIndexColumn>) {
		this.Table = table;
		this.columns = columns;
	}

	public var ColumnNames(get, never):Array<String>;

	function get_ColumnNames():Array<String> {
		return [for (c in columns) c.ColumnName];
	}

	/** Adds another column to the group. */
	public macro function And(self:Expr, property:Expr):Expr {
		final read = EntityTableBuilder.Read(macro $self.Table, property);
		return macro $self.AndNamed($v{read.name}, ${read.type}, $v{read.nullable});
	}

	public function AndNamed(name:String, type:SqlType, nullable:Bool):ColumnsBuilder<T> {
		Table.ColumnNamed(name, type, nullable).Definition;
		columns.push(new DatabaseIndexColumn(name));
		return this;
	}

	/** Sorts the column most recently named descending. */
	public function Descending():ColumnsBuilder<T> {
		columns[columns.length - 1].SortOrder = DatabaseSortOrder.Descending;
		return this;
	}

	public function Index(?name:String):ColumnsBuilder<T> {
		return AddIndex(name, false, BTree);
	}

	public function IndexUsing(type:IndexType, ?name:String):ColumnsBuilder<T> {
		return AddIndex(name, false, type);
	}

	public function UniqueIndex(?name:String):ColumnsBuilder<T> {
		return AddIndex(name, true, BTree);
	}

	function AddIndex(name:Null<String>, isUnique:Bool, type:IndexType):ColumnsBuilder<T> {
		Table.Definition.IndexOver(name == null ? DerivedName("IX") : name, columns.copy(), isUnique, false, null, IndexTypes.Method(type));
		return this;
	}

	public function Unique(?name:String):ColumnsBuilder<T> {
		Table.Definition.Unique(name == null ? DerivedName("UQ") : name, ColumnNames);
		return this;
	}

	/** The table's composite primary key, over these columns. */
	public function PrimaryKey(?name:String):ColumnsBuilder<T> {
		final table = Table.Definition;
		table.Constraints = [for (c in table.Constraints) if (!Std.isOfType(c, DatabasePrimaryKeyConstraint)) c];
		table.PrimaryKey(name == null ? 'PK_${table.Name}' : name, ColumnNames);
		return this;
	}

	function DerivedName(prefix:String):String {
		return '${prefix}_${Table.Definition.Name}_${ColumnNames.join("_")}';
	}
}
