package codequery.schemabuilder;

import codequery.migrations.*;
import codequery.sqlexpressions.ColumnDefinition;
import codequery.migrations.CheckExpressionRenderer;
import codequery.migrations.DatabaseColumnDefinition;
import codequery.migrations.DatabaseColumnType;
import codequery.migrations.DatabaseIndexDefinition;
import codequery.migrations.DatabaseTableConstraint;
import codequery.migrations.DatabaseTableDefinition;
import codequery.schemabuilder.TableBuilder;
#if macro
import codequery.inspection.SchemaInspector;
import codequery.migrations.ColumnBuilderMacros;
import codequery.migrations.SchemaMembers;
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
using haxe.macro.ExprTools;
#end

/**
	A table built against its entity: `Property(e -> e.id)` adds the column the property maps to,
	typed from the property, and the constraints name their columns the same way.
**/
class DatabaseTableBuilder<T> {
	final tableName:String;
	final databaseBuilder:DatabaseBuilder;
	final columns:Array<DatabaseColumnDefinition> = [];
	final constraints:Array<DatabaseTableConstraint> = [];
	final indexes:Array<DatabaseIndexDefinition> = [];

	public function new(tableName:String, databaseBuilder:DatabaseBuilder) {
		this.tableName = tableName;
		this.databaseBuilder = databaseBuilder;
	}

	/** A column for a property, typed from it: an `Int` is an INT, a `Null<Int>` a nullable one. */
	public macro function Property(self:Expr, property:Expr):Expr {
		final entity = EntityOf(self);
		final field = ColumnBuilderMacros.FieldOf(entity, property);
		final kind = SchemaInspector.Classify(field.type);
		final type = macro $p{["codequery", "migrations", "DatabaseColumnType", kind.type]};
		return macro $self.PropertyNamed($v{field.name}, $type, $v{kind.nullable});
	}

	/** What `Property` expands to: the builder for the column, of the kind its type gets. */
	public function PropertyNamed(name:String, type:DatabaseColumnType, nullable:Bool):Dynamic {
		final builder:Dynamic = switch type {
			case Int: new IntColumnBuilder(name);
			case BigInt: new BigIntColumnBuilder(name);
			case SmallInt: new SmallIntColumnBuilder(name);
			case TinyInt: new TinyIntColumnBuilder(name);
			case Float: new FloatColumnBuilder(name);
			case Double: new DoubleColumnBuilder(name);
			case Decimal: new DecimalColumnBuilder(name);
			case VarChar | Text | NVarChar | NText: new StringColumnBuilder(name);
			case Char | NChar: new CharColumnBuilder(name, 1);
			case Boolean: new BooleanColumnBuilder(name);
			case DateTime | Timestamp: new DateTimeColumnBuilder(name);
			case Date: new DateColumnBuilder(name);
			case DateTimeOffset: new DateTimeOffsetColumnBuilder(name);
			case Time: new TimeColumnBuilder(name);
			case Guid: new GuidColumnBuilder(name);
			case VarBinary | Binary | Blob: new BinaryColumnBuilder(name);
			case Json: new JsonColumnBuilder(name);
			case _: throw 'A $name of type $type cannot be a column';
		}
		final definition:DatabaseColumnDefinition = builder.Build();
		definition.IsNullable = nullable;
		columns.push(definition);
		return builder;
	}

	// Constraints

	/** `HasPrimaryKey(e -> e.id, e -> e.other)`, or `HasPrimaryKey("PK_x", e -> e.id)`. */
	public macro function HasPrimaryKey(self:Expr, args:Array<Expr>):Expr {
		final named = Named(self, args);
		return macro $self.PrimaryKeyOn(${named.name}, $v{named.columns});
	}

	public function PrimaryKeyOn(?name:String, columns:Array<String>):DatabaseTableBuilder<T> {
		constraints.push(new DatabasePrimaryKeyConstraint(name == null ? 'PK_$tableName' : name, columns));
		return this;
	}

	/**
		`HasForeignKey(Parent, c -> c.parentId, p -> p.id, ?onDelete, ?onUpdate)`, or the same with a
		name first — C#'s `HasForeignKey<Parent>(…)`.
	**/
	public macro function HasForeignKey(self:Expr, args:Array<Expr>):Expr {
		var name = macro null;
		var rest = args;
		switch args[0].expr {
			case EConst(CString(_)):
				name = args[0];
				rest = args.slice(1);
			case _:
		}
		final referenced = SchemaMembers.ClassTypeOf(rest[0]);
		final column = ColumnBuilderMacros.FieldOf(EntityOf(self), rest[1]).name;
		final referencedColumn = ColumnBuilderMacros.FieldOf(referenced, rest[2]).name;
		final onDelete = rest.length > 3 ? rest[3] : macro null;
		final onUpdate = rest.length > 4 ? rest[4] : macro null;
		return macro $self.ForeignKeyOn($name, $v{column}, $v{SchemaMembers.PathOf(referenced)}, $v{referenced.name}, $v{referencedColumn}, $onDelete, $onUpdate);
	}

	public function ForeignKeyOn(?name:String, column:String, referencedEntity:String, referencedFallback:String, referencedColumn:String,
			?onDelete:DatabaseForeignKeyAction, ?onUpdate:DatabaseForeignKeyAction):DatabaseTableBuilder<T> {
		final referencedTable = databaseBuilder.TableNameOf(referencedEntity, referencedFallback);
		constraints.push(new DatabaseForeignKeyConstraint(
			name == null ? 'FK_${tableName}_${column}_${referencedTable}_$referencedColumn' : name,
			[column], referencedTable, [referencedColumn], onDelete, onUpdate));
		return this;
	}

	/** `HasUnique(e -> e.name)`, or `HasUnique("UQ_x", e -> e.name)`. */
	public macro function HasUnique(self:Expr, args:Array<Expr>):Expr {
		final named = Named(self, args);
		return macro $self.UniqueOn(${named.name}, $v{named.columns});
	}

	public function UniqueOn(?name:String, columns:Array<String>):DatabaseTableBuilder<T> {
		constraints.push(new DatabaseUniqueConstraint(name == null ? 'UQ_${tableName}_${columns.join("_")}' : name, columns));
		return this;
	}

	/** `HasCheck("CK_x", e -> e.price > 0)`. */
	public macro function HasCheck(self:Expr, name:Expr, expression:Expr):Expr {
		final sql = CheckExpressionRenderer.RenderEntity(expression, expression.pos);
		return macro $self.CheckOn($name, $sql);
	}

	public function CheckOn(name:String, expression:String):DatabaseTableBuilder<T> {
		constraints.push(new DatabaseCheckConstraint(name, expression));
		return this;
	}

	// Indexes

	/**
		`HasIndex(e -> e.name)`, `HasIndex("IX_x", e -> e.name)`, or
		`HasIndex("IX_x", idx -> idx.Column("Name").Unique())`.
	**/
	public macro function HasIndex(self:Expr, args:Array<Expr>):Expr {
		// A lambda that builds rather than names a property configures an IndexBuilder.
		if (args.length == 2 && args[0].expr.match(EConst(CString(_))) && !IsPropertyLambda(args[1])) {
			return macro $self.IndexBuilt(${args[0]}, ${args[1]});
		}
		final named = Named(self, args);
		return macro $self.IndexOn(${named.name}, $v{named.columns});
	}

	public function IndexOn(?name:String, columns:Array<String>):DatabaseTableBuilder<T> {
		indexes.push(new DatabaseIndexDefinition(name == null ? 'IX_${tableName}_${columns.join("_")}' : name,
			columns.map(c -> new DatabaseIndexColumn(c))));
		return this;
	}

	public function IndexBuilt(name:String, configure:IndexBuilder->Void):DatabaseTableBuilder<T> {
		final builder = new IndexBuilder(name);
		configure(builder);
		indexes.push(builder.Build());
		return this;
	}

	public function Build():DatabaseTableDefinition {
		final table = new DatabaseTableDefinition(tableName);
		table.Columns = columns;
		table.Constraints = constraints;
		table.Indexes = indexes;
		databaseBuilder.RegisterTable(table);
		return table;
	}

	#if macro
	static function EntityOf(self:Expr):ClassType {
		return switch Context.typeof(self).follow() {
			case TInst(_, [entity]):
				switch entity.follow() {
					case TInst(t, _): t.get();
					case t: Context.error('${t.toString()} is not an entity class', self.pos);
				}
			case t: Context.error('${t.toString()} is not a table builder', self.pos);
		}
	}

	/** An optional leading name, then the columns the property lambdas name. */
	static function Named(self:Expr, args:Array<Expr>):{name:Expr, columns:Array<String>} {
		var name = macro null;
		var rest = args;
		if (args.length > 0) {
			switch args[0].expr {
				case EConst(CString(_)):
					name = args[0];
					rest = args.slice(1);
				case _:
			}
		}
		final entity = EntityOf(self);
		return {name: name, columns: [for (property in rest) ColumnBuilderMacros.FieldOf(entity, property).name]};
	}

	static function IsPropertyLambda(e:Expr):Bool {
		return switch e.expr {
			case EFunction(_, {expr: body}): Unwrap(body).expr.match(EField(_, _, _));
			case _: false;
		}
	}

	static function Unwrap(e:Expr):Expr {
		return switch e.expr {
			case EReturn(inner) if (inner != null): Unwrap(inner);
			case EParenthesis(inner) | EMeta(_, inner) | EBlock([inner]): Unwrap(inner);
			case _: e;
		}
	}
	#end
}
