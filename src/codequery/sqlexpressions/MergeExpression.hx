package codequery.sqlexpressions;

/**
	A `MERGE` statement as data: reconcile a target table with a source row set on a match
	condition, running an action per matched and unmatched row. Standard SQL, which PostgreSQL 15+
	and SQL Server speak; MySQL and SQLite have upsert forms of their own instead.
**/
class MergeExpression implements ISqlStatement {
	public final Target:ISqlSource;
	public final Source:ISqlSource;
	public final On:ISqlExpression;
	public final Actions:Array<MergeAction> = [];

	public function new(target:ISqlSource, source:ISqlSource, on:ISqlExpression) {
		this.Target = target;
		this.Source = source;
		this.On = on;
	}

	/** The target first and the source second, which is the order a lambda's parameters bind to them. */
	public function AllSources():Array<ISqlSource> {
		return [Target, Source];
	}
}
