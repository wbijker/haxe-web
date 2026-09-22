package codequery.queries;

import codequery.RowShape;
import codequery.execution.DatabaseConfiguration;
import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.RowProjection;
import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.DeleteExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.SetAssignment;
import codequery.sqlexpressions.SelectExpression;
import codequery.sqlexpressions.SourceContext;
import codequery.sqlexpressions.SqlBinaryOperator;
import codequery.sqlexpressions.UpdateExpression;

/**
	What `IUpdateQuery` and `IDeleteQuery` are, underneath.

	As with `SelectQueryImpl`, the row types live on the abstracts wrapping this, so building the
	statement needs no generics — and an update and a delete accumulate the same way, so one class
	does both and carries whichever statement it was started with.

	Every clause answers with a query of its own; the one it was asked of is unchanged.

	As on `SelectQueryImpl`, a clause written as a lambda is compiled to a callback over the rows'
	columns and handed to the method of the same name here — `Where`, `Set`, `Returning` — which
	calls it and adds what it answers with.
**/
class MutationQueryImpl {
	public final Update:Null<UpdateExpression>;
	public final Delete:Null<DeleteExpression>;

	final context:SourceContext;

	/** The rows a lambda names: the table's, then the source's where there is one. */
	public final Rows:Array<RowShape>;

	/** Where the statement runs, where it was begun on a table of a built schema; null renders only. */
	public var Configuration:Null<DatabaseConfiguration>;

	function new(update:Null<UpdateExpression>, delete:Null<DeleteExpression>, context:SourceContext, rows:Array<RowShape>) {
		this.Update = update;
		this.Delete = delete;
		this.context = context;
		this.Rows = rows;
	}

	/** Begins an UPDATE of a table's rows. */
	public static function Updating(table:QualifiedTableName, ?configuration:DatabaseConfiguration, ?shape:RowShape):MutationQueryImpl {
		final context = new SourceContext();
		final query = new MutationQueryImpl(new UpdateExpression(context.AddTableSource(table)), null, context, [Shaped(shape, table)]);
		query.Configuration = configuration;
		return query;
	}

	static function Shaped(shape:Null<RowShape>, table:QualifiedTableName):RowShape {
		return shape != null ? shape : RowShape.Unshaped('the table ${table.Name}');
	}

	/** `WHERE <predicate>`, the predicate a callback over the rows' columns. */
	public function Where(predicate:Dynamic):MutationQueryImpl {
		return WhereCondition(RowShape.Call(predicate, Rows));
	}

	/**
		`SET <column> = <value>`: the column a callback naming one of the table's, the value a
		callback over every row the statement has — or an expression already, where it was a value.
	**/
	public function Set(column:Dynamic, value:Dynamic):MutationQueryImpl {
		final target = RowShape.Call(column, [Rows[0]]);
		final assigned:ISqlExpression = Std.isOfType(value, ISqlExpression) ? value : RowShape.Call(value, Rows);
		return SetColumn(target, assigned);
	}

	/** `RETURNING <projection>`, the projection a callback over the rows' columns. */
	public function Returning(projection:Dynamic):MutationQueryImpl {
		return ReturningProjection(RowProjection.Selection(RowShape.Call(projection, Rows)));
	}

	/** A statement derived from this one runs where this one does. */
	function Carrying(derived:MutationQueryImpl):MutationQueryImpl {
		derived.Configuration = Configuration;
		return derived;
	}

	/**
		Begins an `UPDATE … FROM <source>`, drawing its new values from another query.

		The source is registered on this statement's own context, so its alias cannot collide with
		the target's — and a lambda then names the target first and the source second.
	**/
	public static function UpdatingFrom(table:QualifiedTableName, source:SelectQueryImpl, ?shape:RowShape):MutationQueryImpl {
		final context = new SourceContext();
		final statement = new UpdateExpression(context.AddTableSource(table));
		statement.FromSources.push(context.AddQuerySource(source.ToExpression()));
		return new MutationQueryImpl(statement, null, context, [Shaped(shape, table), source.AsRow()]);
	}

	/** Begins a `DELETE … USING <source>`, correlated with another query. */
	public static function DeletingUsing(table:QualifiedTableName, source:SelectQueryImpl, ?shape:RowShape):MutationQueryImpl {
		final context = new SourceContext();
		final statement = new DeleteExpression(context.AddTableSource(table));
		statement.FromSources.push(context.AddQuerySource(source.ToExpression()));
		return new MutationQueryImpl(null, statement, context, [Shaped(shape, table), source.AsRow()]);
	}

	/** Begins a DELETE from a table. */
	public static function Deleting(table:QualifiedTableName, ?configuration:DatabaseConfiguration, ?shape:RowShape):MutationQueryImpl {
		final context = new SourceContext();
		final query = new MutationQueryImpl(null, new DeleteExpression(context.AddTableSource(table)), context, [Shaped(shape, table)]);
		query.Configuration = configuration;
		return query;
	}

	/** What `Set` compiles down to. */
	public function SetColumn(column:ColumnSqlExpression, value:ISqlExpression):MutationQueryImpl {
		if (Update == null) {
			throw "Only an update sets columns";
		}
		final updated = Update.Fork();
		updated.Assignments.push(new SetAssignment(column, value));
		return Carrying(new MutationQueryImpl(updated, null, context.Fork(), Rows));
	}

	public function WhereCondition(condition:ISqlExpression):MutationQueryImpl {
		if (Update != null) {
			final updated = Update.Fork();
			updated.Where = And(updated.Where, condition);
			return Carrying(new MutationQueryImpl(updated, null, context.Fork(), Rows));
		}
		final deleted = Delete.Fork();
		deleted.Where = And(deleted.Where, condition);
		return Carrying(new MutationQueryImpl(null, deleted, context.Fork(), Rows));
	}

	/** What `Returning` compiles down to: the columns the statement hands back per row it touched. */
	public function ReturningProjection(selection:ISqlExpression):MutationQueryImpl {
		if (Update != null) {
			final updated = Update.Fork();
			updated.Returning.push(selection);
			return Carrying(new MutationQueryImpl(updated, null, context.Fork(), Rows));
		}
		final deleted = Delete.Fork();
		deleted.Returning.push(selection);
		return Carrying(new MutationQueryImpl(null, deleted, context.Fork(), Rows));
	}

	/** The statement built so far. */
	public function ToExpression():codequery.sqlexpressions.ISqlStatement {
		return Update != null ? Update : Delete;
	}

	/** How many rows it changed. Runs the statement, so it needs a connection to run it against. */
	public function Execute():Int {
		if (Configuration == null) {
			return RowCount.NeedsAConnection(Update != null ? "An update" : "A delete", "ToExpression()");
		}
		return Configuration.Execute(ToExpression());
	}

	static function And(existing:Null<ISqlExpression>, condition:ISqlExpression):ISqlExpression {
		return existing == null ? condition : new BinarySqlExpression(existing, SqlBinaryOperator.And, condition);
	}
}
