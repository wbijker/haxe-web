package codequery.queries;

import codequery.sqlexpressions.ColumnSqlExpression;
import codequery.sqlexpressions.ConflictAction;
import codequery.sqlexpressions.IdentityOverride;
import codequery.sqlexpressions.ISqlExpression;
import codequery.sqlexpressions.InsertExpression;
import codequery.sqlexpressions.SetAssignment;

/** What `IInsertQuery` is, underneath. */
class InsertQueryImpl {
	public final Insert:InsertExpression;

	public function new(insert:InsertExpression) {
		this.Insert = insert;
	}

	public function ToExpression():InsertExpression {
		return Insert;
	}

	/** What `OnConflict` compiles down to. */
	public function ConflictOn(columns:Array<String>):InsertQueryImpl {
		for (column in columns) {
			Insert.ConflictColumns.push(column);
		}
		// Nothing until something says otherwise, which is the harmless half of the pair.
		Insert.OnConflict = DoNothing;
		return this;
	}

	/** What `Update` compiles down to: the conflicting row is set rather than left. */
	public function ConflictUpdate(column:ColumnSqlExpression, value:ISqlExpression):InsertQueryImpl {
		Insert.OnConflict = DoUpdate;
		Insert.ConflictUpdates.push(new SetAssignment(column, value));
		return this;
	}

	/** What `Overriding` compiles down to. */
	public function Override(mode:IdentityOverride):InsertQueryImpl {
		Insert.Overriding = mode;
		return this;
	}

	/** What `Returning` compiles down to. */
	public function ReturningProjection(selection:ISqlExpression):InsertQueryImpl {
		Insert.Returning.push(selection);
		return this;
	}

	/** How many rows it wrote. Runs the statement, so it needs a connection to run it against. */
	public function Execute():Int {
		return RowCount.NeedsAConnection("An insert", "ToExpression()");
	}
}
