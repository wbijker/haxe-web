package codequery;

import codequery.queries.IQuery;
import codequery.queries.ISelectQuery;
import codequery.queries.IDeleteQuery;
import codequery.queries.IUpdateQuery;
import codequery.queries.MutationQueryImpl;
import codequery.queries.SelectQueryImpl;
import codequery.sqlexpressions.ExpressionConverter;
import codequery.sqlexpressions.ColumnsBuilder;
import codequery.sqlexpressions.InsertConverter;
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
	/** The table, name and schema together, as every statement over it needs both. */
	public final Table:QualifiedTableName;

	public function new(table:QualifiedTableName) {
		this.Table = table;
	}

	/** The table name, unqualified. `Table` is the one to pass on, since a name alone loses the schema. */
	public var TableName(get, never):String;

	function get_TableName():String {
		return Table.Name;
	}

	public function From():ISelectQuery<T> {
		return cast SelectQueryImpl.OverTable(Table);
	}

	/** Begins an UPDATE of this table's rows. */
	public function Update():IUpdateQuery<T> {
		return cast MutationQueryImpl.Updating(Table);
	}

	/** Begins a DELETE from this table. */
	public function Delete():IDeleteQuery<T> {
		return cast MutationQueryImpl.Deleting(Table);
	}

	/**
		Begins an `UPDATE … FROM <source>`. A lambda over it names this table first and the
		source's rows second.
	**/
	public macro function UpdateFrom(self:Expr, source:Expr):Expr {
		return ExpressionConverter.MutationFrom(self, source, "UpdatingFrom", "IUpdateQuery2");
	}

	/** Begins a `DELETE … USING <source>`, correlated with it. */
	public macro function DeleteUsing(self:Expr, source:Expr):Expr {
		return ExpressionConverter.MutationFrom(self, source, "DeletingUsing", "IDeleteQuery2");
	}

	/**
		Begins an insert that has more to say than its rows — what to do where a row is already
		there, what to hand back. C#'s `Upsert`.
	**/
	public macro function Upsert(self:Expr, entry:Expr):Expr {
		final entity = ExpressionConverter.EntityOf(self);
		final statement = ExpressionConverter.ConvertInsert(self, entry, entity);
		return ExpressionConverter.AnsweringInsert(
			macro new codequery.queries.InsertQueryImpl($statement), self);
	}

	/**
		Inserts several entities at once — one statement, a row of values each. A strategy says how
		the values reach the database, and whether the rows are checked before they are sent.
	**/
	public macro function InsertMany(self:Expr, entries:Expr, ?strategy:Expr):Expr {
		final entity = ExpressionConverter.EntityOf(self);
		if (ExpressionConverter.Omitted(strategy)) {
			return ExpressionConverter.ConvertInsertMany(self, entries, entity);
		}
		final statement = ExpressionConverter.ConvertInsertMany(self, macro entries, entity);
		final planned = InsertConverter.Strategised(statement, self, macro entries, entity, strategy);
		return macro {
			final entries = $entries;
			$planned;
		};
	}

	/**
		What a load of the rows' own keys owes the sequence afterwards: the statement that moves the
		table's key generator past the highest of them, or null where the strategy owes it nothing.
	**/
	public macro function ResyncStatement(self:Expr, entries:Expr, strategy:Expr):Expr {
		final entity = ExpressionConverter.EntityOf(self);
		return InsertConverter.Resync(self, entries, entity, strategy);
	}

	/** `INSERT … SELECT` — the rows come from a query rather than from values. */
	public macro function InsertFrom(self:Expr, source:Expr):Expr {
		final entity = ExpressionConverter.EntityOf(self);
		return ExpressionConverter.ConvertInsertFrom(self, source, entity);
	}

	/**
		Inserts one entity.

		C# reads the row's values off it by reflection and answers with the number of rows written.
		Here the reading is done while compiling — the macro knows the entity and emits a read per
		column — and nothing is written, because no driver can execute; `InsertExpression` is the
		statement that would be.
	**/
	public macro function Insert(self:Expr, entry:Expr, ?strategy:Expr):Expr {
		final entity = ExpressionConverter.EntityOf(self);
		if (ExpressionConverter.Omitted(strategy)) {
			return ExpressionConverter.ConvertInsert(self, entry, entity);
		}
		final statement = ExpressionConverter.ConvertInsert(self, macro entry, entity);
		final planned = InsertConverter.Strategised(statement, self, macro [entry], entity, strategy);
		return macro {
			final entry = $entry;
			$planned;
		};
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

		final name = ColumnsBuilder.TableNameOfType(entity);
		return macro new codequery.DbTable(new codequery.QualifiedTableName($v{name}));
	}
}
