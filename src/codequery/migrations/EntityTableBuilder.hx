package codequery.migrations;

import codequery.migrations.ColumnBuilder;
import codequery.migrations.DatabaseColumnType;
import codequery.migrations.DatabaseIndexDefinition;
import codequery.migrations.DatabaseTableConstraint;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.sqlexpressions.SqlType;
#if macro
import codequery.migrations.CheckExpressionRenderer;
import codequery.migrations.ColumnBuilderMacros;
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

	/**
		Configures the column `property` maps to: `t.Column(a -> a.name)`. The builder is typed by
		what the property is — a string gets `StringColumnBuilder`, a `Decimal` the one with
		`Precision` — as C#'s overloads of `Column` choose it.
	**/
	public macro function Column(self:Expr, property:Expr):Expr {
		return ColumnBuilderMacros.ColumnCall(self, property);
	}

	/** The column by name, made from its query-side type where the table has none yet. */
	public function ColumnNamed(name:String, type:SqlType, nullable:Bool):ColumnBuilder<T, Dynamic> {
		return new ColumnBuilder<T, Dynamic>(this, name, DatabaseColumnTypes.OfSqlType(type).type, nullable, false, type);
	}

	// What `Column` expands to: the builder of the kind the property's type gets.

	public function StringColumn(name:String, type:DatabaseColumnType, nullable:Bool, ?entity:String):StringColumnBuilder<T> {
		return new StringColumnBuilder<T>(this, name, type, nullable, entity);
	}

	public function BinaryColumn(name:String, type:DatabaseColumnType, nullable:Bool, ?entity:String):BinaryColumnBuilder<T> {
		return new BinaryColumnBuilder<T>(this, name, type, nullable, entity);
	}

	public function DecimalColumn<P>(name:String, type:DatabaseColumnType, nullable:Bool, ?entity:String):DecimalColumnBuilder<T, P> {
		return new DecimalColumnBuilder<T, P>(this, name, type, nullable, entity);
	}

	public function DateTimeColumn<P>(name:String, type:DatabaseColumnType, nullable:Bool, ?entity:String):DateTimeColumnBuilder<T, P> {
		return new DateTimeColumnBuilder<T, P>(this, name, type, nullable, entity);
	}

	public function TimeColumn<P>(name:String, type:DatabaseColumnType, nullable:Bool, ?entity:String):TimeColumnBuilder<T, P> {
		return new TimeColumnBuilder<T, P>(this, name, type, nullable, entity);
	}

	public function PlainColumn<P>(name:String, type:DatabaseColumnType, nullable:Bool, isGuid:Bool = false, ?entity:String):ColumnBuilder<T, P> {
		return new ColumnBuilder<T, P>(this, name, type, nullable, isGuid, null, entity);
	}

	/**
		A CHECK spanning columns — `Check("CK_x", r -> r.start < r.end)` — a table constraint rather
		than a column's, since no one column owns it. Written SQL is taken as it stands.
	**/
	public macro function Check(self:Expr, name:Expr, expression:Expr):Expr {
		return switch expression.expr {
			case EFunction(_, _):
				final sql = CheckExpressionRenderer.RenderEntity(expression, expression.pos);
				macro $self.CheckSql($name, $sql);
			case _:
				macro $self.CheckSql($name, $expression);
		}
	}

	/** What `Check` expands to. */
	public function CheckSql(name:String, expression:String):EntityTableBuilder<T> {
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
