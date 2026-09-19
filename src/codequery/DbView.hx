package codequery;

import codequery.queries.ISelectQuery;
import codequery.queries.IQueryTable;
import codequery.queries.SelectQueryImpl;
import codequery.sqlexpressions.SelectExpression;
#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
import haxe.macro.Type;

using haxe.macro.TypeTools;
#end

/**
	A view, declared as a schema member the way a table is:

	```haxe
	public final AvailabilityGaps:DbView<AvailabilityGap> = DbView.of(Bookings.From()…);
	```

	Selected from exactly as a table is — its name comes from the row type's `@tableName`, and a
	query over it neither knows nor cares that it is a view. What it holds beyond that is the query
	it is defined by, which is what creating it in the database would need.
**/
class DbView<T> implements IQueryTable {
	/** The view, name and schema together. */
	public final Table:QualifiedTableName;

	/** The query the view is defined by, for whatever would create it. */
	public final Definition:Null<SelectExpression>;

	public function new(table:QualifiedTableName, ?definition:SelectExpression) {
		this.Table = table;
		this.Definition = definition;
	}

	/** Begins a SELECT over this view. */
	public function From():ISelectQuery<T> {
		return cast SelectQueryImpl.OverTable(Table);
	}

	/**
		Declares the view for the row type the member is typed as, taking its name from that type,
		and defined by `query`.
	**/
	public static macro function of(query:Expr):Expr {
		final expected = Context.getExpectedType();
		if (expected == null) {
			Context.error("DbView.of() needs the member to declare its type, e.g. var Gaps:DbView<AvailabilityGap> = DbView.of(…)",
				Context.currentPos());
		}

		final row = switch expected.follow() {
			case TInst(_, [t]): t;
			case t: Context.error('DbView.of() expected a DbView<T>, got ${t.toString()}', Context.currentPos());
		}

		final name = codequery.sqlexpressions.ColumnsBuilder.TableNameOfType(row);
		final definition = macro(cast $query : codequery.queries.SelectQueryImpl).ToExpression();
		return macro new codequery.DbView(new codequery.QualifiedTableName($v{name}), $definition);
	}
}
