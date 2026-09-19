package codequery;

import codequery.queries.IQuery;
import codequery.queries.ISelectQuery;
import codequery.queries.SelectQuery;
import codequery.sqlexpressions.ColumnsBuilder;
import codequery.sqlexpressions.TableSqlSource;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
#end

/**
	A database table for an entity type, declared as a schema member:

	```haxe
	public final Deliveries:DbTable<Delivery> = DbTable.of();
	```

	The table's name comes from the entity type's `@tableName`, or from the type's own name. C#
	writes this as `=> new()` and finds the name by reflecting over the entity at runtime; `of()`
	resolves it while compiling, from the type the member is declared as.
**/
class DbTable<T> implements IQuery<T> {
	/**
		The table as the statement names it — the same source the entity's generated columns are
		bound to, so a column and the FROM it belongs to cannot drift apart.
	**/
	public final Source:TableSqlSource;

	/** The table, name and schema together, as every statement over it needs both. */
	public var Table(get, never):QualifiedTableName;

	function get_Table():QualifiedTableName {
		return Source.Table;
	}

	public function new(source:TableSqlSource) {
		this.Source = source;
	}

	/** The table name, unqualified. `Table` is the one to pass on, since a name alone loses the schema. */
	public var TableName(get, never):String;

	function get_TableName():String {
		return Table.Name;
	}

	public function From():ISelectQuery<T> {
		return SelectQuery.OverSource(Source);
	}

	/**
		Declares the table for the entity the member is typed as, taking its name from that type.
		The C# counterpart of this is the parameterless `new()`.
	**/
	public static macro function of():Expr {
		final expected = Context.getExpectedType();
		if (expected == null) {
			Context.error("DbTable.of() needs the member to declare its type, e.g. var Deliveries:DbTable<Delivery> = DbTable.of()",
				Context.currentPos());
		}

		final entity = switch expected.follow() {
			case TInst(_, [row]): row;
			case t: Context.error('DbTable.of() expected a DbTable<T>, got ${t.toString()}', Context.currentPos());
		}

		final columns = ColumnsBuilder.Of(entity);
		final source = ColumnsBuilder.Member(columns, "Source");
		return macro new codequery.DbTable($source);
	}
}
