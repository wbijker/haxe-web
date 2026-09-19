package codequery;

import codequery.migrations.DatabasePrimaryKeyConstraint;

import codequery.migrations.DatabaseColumnType;
import codequery.migrations.DatabaseTableConstraint;
import codequery.migrations.DatabaseTableDefinition;
import codequery.migrations.SchemaSnapshot;
#if macro
import codequery.inspection.SchemaInspector;
import codequery.migrations.SchemaMembers;
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	A read-only view of the schema for whatever translates a function: the columns, types and
	primary key of the table an entity maps to. Backed by the inspector, and by a built snapshot
	when one is attached, so fluent configuration is visible.
**/
class DatabaseMeta {
	final columns = new Map<String, Array<ColumnMeta>>();
	var snapshot:Null<SchemaSnapshot>;

	/** A shared instance, for where no configuration is in scope. */
	public static final Default = new DatabaseMeta();

	public function new() {}

	/** The table definition for an entity: `meta.GetTable(Author)`. */
	public macro function GetTable(self:Expr, entity:Expr):Expr {
		return macro $self.TableOf($v{SchemaMembers.ClassPathOf(entity)}, () -> codequery.inspection.SchemaInspector.FromType($entity));
	}

	public function TableOf(entity:String, inspect:Void->DatabaseTableDefinition):DatabaseTableDefinition {
		if (snapshot != null) {
			final bound = snapshot.TableOf(entity);
			if (bound != null) {
				return bound;
			}
		}
		return inspect();
	}

	/** The columns of the table an entity maps to, with the primary key identified: `meta.GetColumns(Author)`. */
	public macro function GetColumns(self:Expr, entity:Expr):Expr {
		final row = SchemaMembers.ClassTypeOf(entity);
		final properties = [
			for (field in SchemaInspector.ColumnFields(row))
				macro {property: $v{field.name}, column: $v{SchemaInspector.ColumnNameOf(field)}}
		];
		final list = {expr: EArrayDecl(properties), pos: entity.pos};
		return macro $self.ColumnsOf($v{SchemaMembers.PathOf(row)}, () -> codequery.inspection.SchemaInspector.FromType($entity), $list);
	}

	public function ColumnsOf(entity:String, inspect:Void->DatabaseTableDefinition, properties:Array<{property:String, column:String}>):Array<ColumnMeta> {
		final known = columns.get(entity);
		if (known != null) {
			return known;
		}
		final table = TableOf(entity, inspect);
		var primaryKey:Array<String> = [];
		for (constraint in table.Constraints) {
			final pk = Std.downcast(constraint, DatabasePrimaryKeyConstraint);
			if (pk != null) {
				primaryKey = pk.Columns;
				break;
			}
		}
		final built = [
			for (column in table.Columns) {
				var property:Null<String> = null;
				for (candidate in properties) {
					if (candidate.column.toLowerCase() == column.Name.toLowerCase()) {
						property = candidate.property;
					}
				}
				new ColumnMeta(property == null ? column.Name : property, column.Name, primaryKey.indexOf(column.Name) >= 0,
					column.Type, property);
			}
		];
		columns.set(entity, built);
		return built;
	}

	/** The primary-key column names; empty where the entity has no key. */
	public macro function GetPrimaryKeyColumns(self:Expr, entity:Expr):Expr {
		return macro $self.GetColumns($entity).filter(c -> c.IsPrimaryKey).map(c -> c.ColumnName);
	}

	/** Attaches a built snapshot so fluent customisations win over pure inspection. */
	public function AttachSnapshot(snapshot:SchemaSnapshot):Void {
		this.snapshot = snapshot;
		columns.clear();
	}
}

/** Metadata for one mapped column of an entity. */
class ColumnMeta {
	/** The entity field's name — what a query column reference uses. */
	public final PropertyName:String;

	/** The database column name, honouring `@columnName`. */
	public final ColumnName:String;

	public final IsPrimaryKey:Bool;
	public final Type:DatabaseColumnType;

	/** The backing field's name, or null for a synthesised column. */
	public final Property:Null<String>;

	public function new(propertyName:String, columnName:String, isPrimaryKey:Bool, type:DatabaseColumnType, ?property:String) {
		this.PropertyName = propertyName;
		this.ColumnName = columnName;
		this.IsPrimaryKey = isPrimaryKey;
		this.Type = type;
		this.Property = property;
	}
}
