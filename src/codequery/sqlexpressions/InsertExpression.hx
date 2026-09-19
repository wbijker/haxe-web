package codequery.sqlexpressions;

/**
	An INSERT statement as data — rows of values, or the rows another statement selects.

	The C# original also carries an insert strategy and what to do on a conflict; neither is here
	yet.
**/
class InsertExpression implements ISqlStatement {
	public final Target:ISqlSource;
	public final Columns:Array<ColumnSqlExpression> = [];

	/** One entry per row, each holding a value per column. */
	public final Values:Array<Array<ISqlExpression>> = [];

	/** `INSERT … SELECT`, where the rows come from another statement rather than from values. */
	public var FromSelect:Null<SelectExpression>;

	public final Returning:Array<ISqlExpression> = [];

	public function new(target:ISqlSource) {
		this.Target = target;
	}

	public function AllSources():Array<ISqlSource> {
		return [Target];
	}
}
