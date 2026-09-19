package codequery.sqlexpressions;

/**
	An INSERT statement as data — rows of values, or the rows another statement selects.

	Where a row is already there, `OnConflict` says what to do about it — nothing, or set some of
	its columns to something.
**/
class InsertExpression implements ISqlStatement {
	public final Target:ISqlSource;
	public final Columns:Array<ColumnSqlExpression> = [];

	/** One entry per row, each holding a value per column. */
	public final Values:Array<Array<ISqlExpression>> = [];

	/** `INSERT … SELECT`, where the rows come from another statement rather than from values. */
	public var FromSelect:Null<SelectExpression>;

	public final Returning:Array<ISqlExpression> = [];

	/** What to do about a row that is already there, or null to let the insert fail. */
	public var OnConflict:Null<ConflictAction>;

	/** The columns a conflict is judged on. */
	public final ConflictColumns:Array<String> = [];

	/** What a conflicting row is set to, where the action is to update it. */
	public final ConflictUpdates:Array<SetAssignment> = [];

	/** Whether the insert may write a column the database generates. */
	public var Overriding:IdentityOverride = None;

	/** How the values reach the database. */
	public var Strategy:codequery.InsertStrategy = new codequery.InsertStrategy();

	public function new(target:ISqlSource) {
		this.Target = target;
	}

	public function AllSources():Array<ISqlSource> {
		return [Target];
	}
}
