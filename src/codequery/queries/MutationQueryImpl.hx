package codequery.queries;

import codequery.sqlexpressions.BinarySqlExpression;
import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.DeleteExpression;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.SetAssignment;
import codequery.sqlexpressions.SourceContext;
import codequery.sqlexpressions.SqlBinaryOperator;
import codequery.sqlexpressions.UpdateExpression;

/**
	What `IUpdateQuery` and `IDeleteQuery` are, underneath.

	As with `SelectQueryImpl`, the row types live on the abstracts wrapping this, so building the
	statement needs no generics — and an update and a delete accumulate the same way, so one class
	does both and carries whichever statement it was started with.

	Every clause answers with a query of its own; the one it was asked of is unchanged.
**/
class MutationQueryImpl {
	public final Update:Null<UpdateExpression>;
	public final Delete:Null<DeleteExpression>;

	final context:SourceContext;

	function new(update:Null<UpdateExpression>, delete:Null<DeleteExpression>, context:SourceContext) {
		this.Update = update;
		this.Delete = delete;
		this.context = context;
	}

	/** Begins an UPDATE of a table's rows. */
	public static function Updating(table:QualifiedTableName):MutationQueryImpl {
		final context = new SourceContext();
		return new MutationQueryImpl(new UpdateExpression(context.AddTableSource(table)), null, context);
	}

	/** Begins a DELETE from a table. */
	public static function Deleting(table:QualifiedTableName):MutationQueryImpl {
		final context = new SourceContext();
		return new MutationQueryImpl(null, new DeleteExpression(context.AddTableSource(table)), context);
	}

	/** What `Set` compiles down to. */
	public function SetColumn(column:ColumnSqlExpression, value:ISqlExpression):MutationQueryImpl {
		if (Update == null) {
			throw "Only an update sets columns";
		}
		final updated = Update.Fork();
		updated.Assignments.push(new SetAssignment(column, value));
		return new MutationQueryImpl(updated, null, context.Fork());
	}

	public function WhereCondition(condition:ISqlExpression):MutationQueryImpl {
		if (Update != null) {
			final updated = Update.Fork();
			updated.Where = And(updated.Where, condition);
			return new MutationQueryImpl(updated, null, context.Fork());
		}
		final deleted = Delete.Fork();
		deleted.Where = And(deleted.Where, condition);
		return new MutationQueryImpl(null, deleted, context.Fork());
	}

	/** What `Returning` compiles down to: the columns the statement hands back per row it touched. */
	public function ReturningProjection(selection:ISqlExpression):MutationQueryImpl {
		if (Update != null) {
			final updated = Update.Fork();
			updated.Returning.push(selection);
			return new MutationQueryImpl(updated, null, context.Fork());
		}
		final deleted = Delete.Fork();
		deleted.Returning.push(selection);
		return new MutationQueryImpl(null, deleted, context.Fork());
	}

	/** The statement built so far. */
	public function ToExpression():codequery.sqlexpressions.ISqlStatement {
		return Update != null ? Update : Delete;
	}

	/** How many rows it changed. Runs the statement, so it needs a connection to run it against. */
	public function Execute():Int {
		return RowCount.NeedsAConnection(Update != null ? "An update" : "A delete", "ToExpression()");
	}

	static function And(existing:Null<ISqlExpression>, condition:ISqlExpression):ISqlExpression {
		return existing == null ? condition : new BinarySqlExpression(existing, SqlBinaryOperator.And, condition);
	}
}
