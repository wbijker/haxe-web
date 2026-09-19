package codequery.migrations;

import codequery.migrations.DatabaseIndexDefinition;
import codequery.migrations.DatabaseTableConstraint;

#if macro
import haxe.macro.Expr;
#end

/**
	Several columns taken together, for the constraints that span more than one — a composite key,
	index or unique constraint. Reached by continuing from a column with `And`, so a composite still
	starts where every other piece of configuration starts. C#'s `ColumnsBuilder<TEntity>`.
**/
class ColumnGroupBuilder<TEntity> {
	final table:EntityTableBuilder<TEntity>;
	final definition:DatabaseTableDefinition;
	final columns:Array<DatabaseIndexColumn> = [];

	public function new(table:EntityTableBuilder<TEntity>, definition:DatabaseTableDefinition, first:String) {
		this.table = table;
		this.definition = definition;
		columns.push(new DatabaseIndexColumn(first));
	}

	/** The table these columns belong to. */
	public var Table(get, never):EntityTableBuilder<TEntity>;

	function get_Table():EntityTableBuilder<TEntity> {
		return table;
	}

	/** The columns named so far, in order. */
	public var ColumnNames(get, never):Array<String>;

	function get_ColumnNames():Array<String> {
		return columns.map(c -> c.ColumnName);
	}

	/** Adds another column to the group. */
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
		columns.push(new DatabaseIndexColumn(column));
		return this;
	}

	/** Sorts the column most recently named descending. */
	public function Descending():ColumnGroupBuilder<TEntity> {
		columns[columns.length - 1].SortOrder = DatabaseSortOrder.Descending;
		return this;
	}

	public function Index(?name:String):ColumnGroupBuilder<TEntity> {
		return AddIndex(name, false, null);
	}

	public function IndexUsing(method:String, ?name:String):ColumnGroupBuilder<TEntity> {
		return AddIndex(name, false, method);
	}

	public function UniqueIndex(?name:String):ColumnGroupBuilder<TEntity> {
		return AddIndex(name, true, null);
	}

	function AddIndex(name:Null<String>, isUnique:Bool, method:Null<String>):ColumnGroupBuilder<TEntity> {
		definition.IndexColumns(name == null ? DerivedName("IX") : name, columns.copy(), isUnique, false, null, method);
		return this;
	}

	public function Unique(?name:String):ColumnGroupBuilder<TEntity> {
		definition.Unique(name == null ? DerivedName("UQ") : name, ColumnNames);
		return this;
	}

	/** The table's composite primary key, replacing any key already inferred. */
	public function PrimaryKey(?name:String):ColumnGroupBuilder<TEntity> {
		definition.Constraints = definition.Constraints.filter(c -> !Std.isOfType(c, DatabasePrimaryKeyConstraint));
		definition.PrimaryKey(name == null ? 'PK_${definition.TableName}' : name, ColumnNames);
		return this;
	}

	function DerivedName(prefix:String):String {
		return '${prefix}_${definition.TableName}_${ColumnNames.join("_")}';
	}
}
