package codequery.sqlexpressions;

/**
	A window defined once on the statement and named by the aggregates reading over it — SQL's
	`WINDOW w AS (PARTITION BY … ORDER BY …)`.

	It is a source because that is how a query names it: the window arrives as an extra row, so a
	projection takes it alongside the rows it is over.
**/
class NamedWindowSqlSource implements ISqlSource {
	public final Name:String;
	public final PartitionBy:Array<ISqlExpression>;
	public final OrderBy:Array<OrderByExpression>;

	/** A window is named, and the name is how it is referred to, so the two are the same. */
	public var Alias(default, null):String;

	public function new(name:String, partitionBy:Array<ISqlExpression>, orderBy:Array<OrderByExpression>) {
		this.Name = name;
		this.Alias = name;
		this.PartitionBy = partitionBy;
		this.OrderBy = orderBy;
	}
}
